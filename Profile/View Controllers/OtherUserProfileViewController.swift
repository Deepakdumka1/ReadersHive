//
//  OtherUserProfileViewController.swift
//  Club
//
//  Created by GEU on 24/03/26.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

enum ProfileItem {
    case post(FeedPost)
    case club(Club)
    case shelfHeader(String)
    case shelfBook(Book, rank: Int)
}

class OtherUserProfileViewController: UIViewController {
    
    @IBOutlet weak var moreButton: UIBarButtonItem!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var profile: Profile?
    
    // UI State
    var selectedSegmentIndex: Int = 0 {
        didSet {
            loadCurrentSegmentData()
        }
    }
    
    // Data
    var userPosts: [FeedPost] = []
    var userClubs: [Club] = []
    var userBooksBySection: [ShelfSection] = []
    var allBooksCache: [Book] = []
    
    // Listeners
    private var profileListener: ListenerRegistration?
    private var postsListener: ListenerRegistration?
    private var clubsListener: ListenerRegistration?
    private var shelfListener: ListenerRegistration?
    
    // Current rendered items for Section 1
    var currentItems: [ProfileItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.hidesBottomBarWhenPushed = true
        setupData()
        setupUI()
        registerCells()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Ensure the title is always visible against the white background, even in dark mode
        let textAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Reset to default
        navigationController?.navigationBar.titleTextAttributes = nil
    }
    
    
    private func setupData() {
        guard let userId = profile?.userId else { return }
        let db = Firestore.firestore()
        
        // 1. Listen to Profile changes (followers/following count)
        profileListener = db.collection("profiles").document(userId).addSnapshotListener { [weak self] snapshot, _ in
            if let updatedProfile = try? snapshot?.data(as: Profile.self) {
                self?.profile = updatedProfile
                self?.collectionView.reloadItems(at: [IndexPath(item: 0, section: 0)])
            }
        }
        
        // 2. Fetch User's Posts
        postsListener = db.collection("posts")
            .whereField("userId", isEqualTo: userId)
            .addSnapshotListener { [weak self] snapshot, _ in
                let rawPosts = snapshot?.documents.compactMap { try? $0.data(as: FeedPost.self) } ?? []
                
                // Sort locally to avoid Firestore composite index requirement
                let sortedPosts = rawPosts.sorted {
                    ($0.createdAt ?? Date.distantPast) > ($1.createdAt ?? Date.distantPast)
                }
                
                self?.userPosts = sortedPosts.map { post in
                    var p = post
                    p.name = self?.profile?.fullName ?? "User"
                    p.avatarUrl = self?.profile?.avatarUrl
                    return p
                }
                self?.loadCurrentSegmentData()
            }
            
        // 3. Fetch User's Clubs (where user is a member)
        clubsListener = db.collection("clubs").addSnapshotListener { [weak self] snapshot, _ in
            let allClubs = snapshot?.documents.compactMap { try? $0.data(as: Club.self) } ?? []
            self?.userClubs = allClubs.filter { club in
                club.members?.contains(where: { $0.userId == userId }) ?? false
            }
            self?.loadCurrentSegmentData()
        }
        
        // 4. Fetch User's Bookshelf
        shelfListener = db.collection("bookshelves").document(userId).addSnapshotListener { [weak self] snapshot, _ in
            guard let self = self, let data = snapshot?.data() else { return }
            
            // Parse allBooks cache
            if let booksData = data["allBooks"] as? [[String: Any]] {
                self.allBooksCache = booksData.compactMap { dict -> Book? in
                    guard let id = dict["id"] as? String,
                          let title = dict["title"] as? String,
                          let author = dict["author"] as? String,
                          let url = dict["coverImageURL"] as? String else { return nil }
                    return Book(id: id, title: title, author: author, coverImageURL: url, description: dict["description"] as? String ?? "")
                }
            }
            
            // Parse sections
            if let sectionsData = data["sections"] as? [[String: Any]] {
                self.userBooksBySection = sectionsData.compactMap { dict -> ShelfSection? in
                    guard let typeStr = dict["shelfType"] as? String,
                          let type = ShelfType(rawValue: typeStr),
                          let title = dict["title"] as? String,
                          let booksArray = dict["books"] as? [[String: Any]] else { return nil }
                    
                    let bookRefs = booksArray.compactMap { b -> BookRef? in
                        guard let id = b["id"] as? String else { return nil }
                        return BookRef(id: id)
                    }
                    
                    return ShelfSection(shelfType: type, title: title, books: bookRefs, isPrivate: dict["isPrivate"] as? Bool ?? false)
                }
            }
            self.loadCurrentSegmentData()
        }
    }
    
    private func loadCurrentSegmentData() {
        currentItems.removeAll()
        
        switch selectedSegmentIndex {
        case 0:
            currentItems = userPosts.map { .post($0) }
        case 1:
            currentItems = userClubs.map { .club($0) }
        case 2:
            for section in userBooksBySection {
                currentItems.append(.shelfHeader(section.title))
                let books = section.books.compactMap { ref in
                    allBooksCache.first { $0.id == ref.id }
                }
                for (index, book) in books.enumerated() {
                    currentItems.append(.shelfBook(book, rank: index + 1))
                }
            }
        default:
            break
        }
        
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
    private func setupUI() {
        navigationItem.title = ""
        navigationItem.largeTitleDisplayMode = .never
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        collectionView.collectionViewLayout = createLayout()
        collectionView.dataSource = self
        collectionView.delegate = self
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { [weak self] (sectionIndex, environment) -> NSCollectionLayoutSection? in
            guard let self = self else { return nil }
            if sectionIndex == 0 {
                return self.createProfileSection()
            } else {
                return self.createContentSection(for: sectionIndex, env: environment)
            }
        }
        return layout
    }
    
    private func createProfileSection() -> NSCollectionLayoutSection {
        let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(280))
        let item = NSCollectionLayoutItem(layoutSize: size)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: size, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        return section
    }
    
    private func createContentSection(for sectionIndex: Int, env: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let itemSize: NSCollectionLayoutSize
        let groupSize: NSCollectionLayoutSize
        let group: NSCollectionLayoutGroup
        
        switch selectedSegmentIndex {
        case 0: // Posts
            itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .absolute(260))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
            groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(260))
            group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 8, bottom: 16, trailing: 8)
            
            let section = NSCollectionLayoutSection(group: group)
            let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(50))
            let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
            section.boundarySupplementaryItems = [header]
            return section
            
        case 1: // Clubs
            itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .absolute(260))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 8, bottom: 12, trailing: 8)
            groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(260))
            group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            group.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 16, trailing: 8)
            
            let section = NSCollectionLayoutSection(group: group)
            let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(50))
            let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
            section.boundarySupplementaryItems = [header]
            return section
            
        case 2: // Shelf
            var isEmpty = false
            if sectionIndex > 0 && sectionIndex - 1 < userBooksBySection.count {
                let shelfSection = userBooksBySection[sectionIndex - 1]
                isEmpty = shelfSection.books.isEmpty
            }
            
            let itemSize: NSCollectionLayoutSize
            let groupSize: NSCollectionLayoutSize
            let group: NSCollectionLayoutGroup
            
            if isEmpty {
                itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(150))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(150))
                group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
            } else {
                itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(90))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                groupSize = NSCollectionLayoutSize(widthDimension: .absolute(320), heightDimension: .estimated(300))
                group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, repeatingSubitem: item, count: 3)
                group.interItemSpacing = .fixed(8)
                group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
            }
            
            let section = NSCollectionLayoutSection(group: group)
            if !isEmpty {
                section.orthogonalScrollingBehavior = .groupPaging
            }
            section.interGroupSpacing = 16
            
            var boundaryItems = [NSCollectionLayoutBoundarySupplementaryItem]()
            if sectionIndex == 1 {
                // Section index 1 holds the Segmented Control header
                // We want this section to be full width so the header is centered correctly
                section.contentInsets = NSDirectionalEdgeInsets(top: 16 + 50, leading: 0, bottom: 16, trailing: 0)
                
                let segmentHeaderSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(50))
                let segmentHeader = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: segmentHeaderSize, 
                    elementKind: UICollectionView.elementKindSectionHeader, 
                    alignment: .top
                )
                boundaryItems.append(segmentHeader)
                
                let titleHeaderSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(44))
                let titleHeader = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: titleHeaderSize, elementKind: "ShelfTitleHeader", alignment: .top, absoluteOffset: CGPoint(x: 0, y: 50))
                // Inset the title header back to 16pt since the section is now full width
                titleHeader.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
                boundaryItems.append(titleHeader)
            } else {
                // Subsequent shelf sections
                section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 0, bottom: 16, trailing: 0)
                
                let titleHeaderSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(44))
                let titleHeader = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: titleHeaderSize, elementKind: "ShelfTitleHeader", alignment: .top)
                titleHeader.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
                boundaryItems.append(titleHeader)
            }
            
            section.boundarySupplementaryItems = boundaryItems
            return section
            
        default:
            itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(1))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(1))
            group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            return section
        }
    }
    
    private func registerCells() {
        collectionView.register(UINib(nibName: "OtherUserCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "otherProfileCell")
        collectionView.register(UINib(nibName: "PostsCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "PostsCollectionViewCell")
        collectionView.register(UINib(nibName: "ProfileClubCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "ProfileClubCollectionViewCell")
        collectionView.register(UINib(nibName: "TopBookCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "TopBookCollectionViewCell")
        collectionView.register(BookshelfHeaderCollectionViewCell.self, forCellWithReuseIdentifier: BookshelfHeaderCollectionViewCell.reuseIdentifier)
        collectionView.register(EmptyShelfCell.self, forCellWithReuseIdentifier: EmptyShelfCell.reuseIdentifier)
        
        collectionView.register(ProfileSegmentHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: ProfileSegmentHeaderView.reuseIdentifier)
        
        collectionView.register(
            UINib(nibName: "BookshelfSectionHeaderView", bundle: nil),
            forSupplementaryViewOfKind: "ShelfTitleHeader",
            withReuseIdentifier: "BookshelfSectionHeaderView"
        )
    }
    
    // Simulate setting local state in repository upon follow
    func didTapFollow(in cell: OtherUserCollectionViewCell) {
        guard let targetUser = self.profile,
              let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let isFollowing = targetUser.followers?.contains(currentUserId) ?? false
        
        if isFollowing {
            // Unfollow logic
            db.collection("profiles").document(currentUserId).updateData([
                "following": FieldValue.arrayRemove([targetUser.userId])
            ])
            db.collection("profiles").document(targetUser.userId).updateData([
                "followers": FieldValue.arrayRemove([currentUserId])
            ])
        } else {
            // Follow logic
            db.collection("profiles").document(currentUserId).updateData([
                "following": FieldValue.arrayUnion([targetUser.userId])
            ])
            db.collection("profiles").document(targetUser.userId).updateData([
                "followers": FieldValue.arrayUnion([currentUserId])
            ])
        }
    }
}


//MARK:- UICollection DataViewDelegate and DataSource
extension OtherUserProfileViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if selectedSegmentIndex == 2 {
            return 1 + userBooksBySection.count
        }
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        if selectedSegmentIndex == 2 {
            let shelfSection = userBooksBySection[section - 1]
            let count = shelfSection.books.count
            return count == 0 ? 1 : count
        }
        return currentItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "otherProfileCell", for: indexPath) as! OtherUserCollectionViewCell
            if let user = profile {
                let followersCount = user.followers?.count ?? 0
                let followingCount = user.following?.count ?? 0
                let currentUid = Auth.auth().currentUser?.uid ?? ""
                let isFollowing = user.followers?.contains(currentUid) ?? false
                
                cell.configure(name: user.fullName, imageName: user.avatarUrl, followers: followersCount, following: followingCount, bio: user.description, isFollowed: isFollowing)
                cell.delegate = self
                
                let doesFollowMe = user.following?.contains(currentUid) ?? false
                
                cell.followButton.setTitle(isFollowing ? "Following" : (doesFollowMe ? "Follow Back" : "Follow"), for: .normal)
                cell.followButton.backgroundColor = isFollowing ? .systemGray5 : .systemBlue
                cell.followButton.setTitleColor(isFollowing ? .label : .white, for: .normal)
            }
            // Elevate the zPosition to ensure the Message button is not
            // secretly overlaid by orthogonal layout scroll views from Section 1 headers
            cell.layer.zPosition = 100
            return cell
        }
        else {
            if selectedSegmentIndex == 2 {
                let shelfSection = userBooksBySection[indexPath.section - 1]
                let books = shelfSection.books.compactMap { ref in
                    allBooksCache.first { $0.id == ref.id }
                }
                
                if books.isEmpty {
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: EmptyShelfCell.reuseIdentifier, for: indexPath) as! EmptyShelfCell
                    cell.configure(title: "No books yet", subtitle: "User hasn't added books to this shelf.")
                    return cell
                }
                
                let book = books[indexPath.row]
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TopBookCollectionViewCell", for: indexPath) as! TopBookCollectionViewCell
                cell.configure(with: book, rank: indexPath.row + 1)
                return cell
            }
            
            let item = currentItems[indexPath.row]
            switch item {
            case .post(let post):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PostsCollectionViewCell", for: indexPath) as! PostsCollectionViewCell
                cell.configure(with: post)
                return cell
            case .club(let club):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProfileClubCollectionViewCell", for: indexPath) as! ProfileClubCollectionViewCell
                let actualMemberCount = club.members?.count ?? club.memberCount ?? 0
                cell.configure(with: club.name ?? "", membersCount: actualMemberCount, type: club.category?.displayName ?? "", imageName: club.imagePath)
                return cell
            case .shelfHeader, .shelfBook:
                // Handled natively above for Shelf layout
                break
            }
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader && indexPath.section == 1 {
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ProfileSegmentHeaderView.reuseIdentifier, for: indexPath) as! ProfileSegmentHeaderView
            header.segmentedControl.selectedSegmentIndex = self.selectedSegmentIndex
            header.delegate = self
            return header
        } else if kind == "ShelfTitleHeader" {
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "BookshelfSectionHeaderView", for: indexPath) as! BookshelfSectionHeaderView
            let shelfSection = userBooksBySection[indexPath.section - 1]
            header.configure(title: shelfSection.title, isPrivate: shelfSection.isPrivate)
            return header
        }
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section > 0 && selectedSegmentIndex == 0 {
            let item = currentItems[indexPath.row]
            if case .post(let post) = item {
                let commentsVC = CommentsViewController()
                commentsVC.post = post
                commentsVC.feedData = AppDependencies.shared.feedData
                commentsVC.showPostHeader = true
                commentsVC.hidesBottomBarWhenPushed = true
                if let nav = navigationController {
                    nav.pushViewController(commentsVC, animated: true)
                } else {
                    let navVC = UINavigationController(rootViewController: commentsVC)
                    present(navVC, animated: true)
                }
            }
        }
    }
}

extension OtherUserProfileViewController: ProfileSegmentHeaderDelegate {
    func didChangeSegment(to index: Int) {
        self.selectedSegmentIndex = index
    }
}

//Communication channel from cell->controller
extension OtherUserProfileViewController: OtherUserCardDelegate {
    
    func didTapFollowers() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "FollowersViewController") as? FollowersViewController {
            vc.userProfile = self.profile
            if let nav = navigationController {
                nav.pushViewController(vc, animated: true)
            } else {
                let navVC = UINavigationController(rootViewController: vc)
                present(navVC, animated: true)
            }
        }
    }
    
    func didTapFollowing() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "FollowingViewController") as? FollowingViewController {
            vc.userProfile = self.profile
            if let nav = navigationController {
                nav.pushViewController(vc, animated: true)
            } else {
                let navVC = UINavigationController(rootViewController: vc)
                present(navVC, animated: true)
            }
        }
    }
    
    func didTapFollowButton(cell: OtherUserCollectionViewCell) {
        self.didTapFollow(in: cell)
    }
    
    func didTapMessage(cell: OtherUserCollectionViewCell) {
        guard let user = profile else { return }
        
        AppDependencies.shared.messageDataModel.startConversation(with: user) { [weak self] conversationId in
            guard let self = self else { return }
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            guard let chatVC = storyboard.instantiateViewController(withIdentifier: "ChatViewController") as? ChatViewController else { return }
            
            let conversation = Conversation(
                id: conversationId,
                otherUserId: user.userId,
                otherUserName: user.fullName,
                avatarImage: user.avatarUrl ?? "",
                lastMessage: "",
                lastMessageTimestamp: Date()
            )
            
            chatVC.conversation = conversation
            chatVC.hidesBottomBarWhenPushed = true
            
            DispatchQueue.main.async {
                self.navigationController?.pushViewController(chatVC, animated: true)
            }
        }
    }
    
    func shouldPromptFollowFirst() {
        let alert = UIAlertController(
            title: "Follow Required",
            message: "You need to follow this user before sending a message.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Follow", style: .default) { [weak self] _ in
            guard let self = self else { return }
            // If they can't scroll, maybe the cell is still there
            if let cell = self.collectionView.cellForItem(at: IndexPath(row: 0, section: 0)) as? OtherUserCollectionViewCell {
                self.didTapFollow(in: cell)
            }
        })
        present(alert, animated: true)
    }
}
