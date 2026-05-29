//
//  DiscussionViewController.swift
//  Club
//
//  Created by Manas  on 02/03/26.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class KafkaViewController: UIViewController {
    @IBOutlet var KafkaCollectionView: UICollectionView!
    
    @IBOutlet weak var threeDots: UIBarButtonItem!
    private var listener: ListenerRegistration?
    private var discussionsListener: ListenerRegistration?
    private var chatRoomsListener: ListenerRegistration?
    private var discussionPostsListener: ListenerRegistration?
    let currentUser = "Alice"
    var clubId: String = ""
    var club: Club?
    var clubData: ClubsData!
    var isAdmin: Bool = false
    var isMember: Bool = false
    
    var member: User!
    var clubDetailData: ClubDetailData!
    var clubDetail: ClubDetail!
    var chatRooms: [ChatRoom] = []
    var scheduledDiscussions: [Discussion] = []
    var filter: [Filter] = []
    var discussionPost: [DiscussionPost] = []
    var allDiscussionPosts: [DiscussionPost] = []

    

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = ""
        
//        let appearance = UINavigationBarAppearance()
//            appearance.titleTextAttributes = [
//                .foregroundColor: UIColor.red
//            ]
//            appearance.largeTitleTextAttributes = [
//                .foregroundColor: UIColor.white
//            ]
//            
//            navigationController?.navigationBar.standardAppearance = appearance
//            navigationController?.navigationBar.scrollEdgeAppearance = appearance
//        
        
        

        
        //print("KafkaViewController clubId:", clubId)
        
        //for ignoring safe area on top
        navigationController?.navigationBar.isTranslucent = true
        KafkaCollectionView.contentInsetAdjustmentBehavior = .never
        
        
        KafkaCollectionView.dataSource = self
        KafkaCollectionView.delegate = self
        
        KafkaCollectionView.register(
            UINib(nibName: "ClubHeaderCell", bundle: nil),
            forCellWithReuseIdentifier: "clubHeader_cell"
        )
        
        KafkaCollectionView.register(
            UINib(nibName: "ChatRoomCollectionViewCell", bundle: nil),
            forCellWithReuseIdentifier: "club_cell"
        )
        KafkaCollectionView.register(
            UINib(nibName: "ScheduleDiscussionCollectionViewCell", bundle: nil),
            forCellWithReuseIdentifier: "discussion_cell"
        )
        KafkaCollectionView.register(
            UINib(nibName: "FilterCollectionViewCell", bundle: nil),
            forCellWithReuseIdentifier: "filter_cell"
        )
        KafkaCollectionView.register(
            UINib(nibName: "DiscussionCollectionViewCell", bundle: nil),
            forCellWithReuseIdentifier: "post_cell"
        )
        KafkaCollectionView.register(UINib(nibName: "JoinButtonCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "join_cell")
        
        KafkaCollectionView.register(UINib(nibName: "SectionHeaderViewClubDetailCollectionReusableView", bundle: nil),
                                     forSupplementaryViewOfKind: "header", withReuseIdentifier: "detailheader_view")
    
        
        loadData()
        setupMenu()
        
        let layout = generateLayout()
        KafkaCollectionView.setCollectionViewLayout(layout, animated: true)
        

        // Do any additional setup after loading the view.
    }
    
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.y

        if offset > 120 {
            navigationItem.title = clubDetail.club?.name
        } else {
            navigationItem.title = ""
        }
    }
    
    func loadData() {
        listener?.remove()
        listener = Firestore.firestore().collection("clubs").document(clubId).addSnapshotListener { [weak self] snapshot, error in
            guard let self = self, let club = try? snapshot?.data(as: Club.self) else { return }
            
            self.club = club
            
            if var detail = self.clubDetailData.detail(for: self.clubId) {
                detail.club = club
                self.clubDetail = detail
                
                self.chatRooms = detail.chatRooms
                self.scheduledDiscussions = detail.upcomingDiscussions
// Use backend filters if available, else fallback to your rich filters
self.filter = detail.filters.isEmpty ? [
    Filter(title: "Newest", isSelected: true),
    Filter(title: "Popular", isSelected: false),
    Filter(title: "Theme", isSelected: false),
    Filter(title: "Setting", isSelected: false),
    Filter(title: "Spoiler", isSelected: false),
    Filter(title: "Author", isSelected: false)
] : detail.filters

// Keep real posts
self.discussionPost = detail.posts
self.allDiscussionPosts = detail.posts
                
                self.isMember = isUserMember(club)
                self.isAdmin = isUserAdmin(club)
            } else {
                let initialFilters = [
                    Filter(title: "Newest", isSelected: true),
                    Filter(title: "Popular", isSelected: false),
                    Filter(title: "Theme", isSelected: false),
                    Filter(title: "Setting", isSelected: false),
                    Filter(title: "Spoiler", isSelected: false),
                    Filter(title: "Author", isSelected: false)
                ]
                let newDetail = ClubDetail(
                    club: club,
                    members: club.members?.map { $0.userId } ?? [],
                    admins: club.members?.filter { $0.role == "admin" }.map { $0.userId } ?? [],
                    coAdmins: nil,
                    chatRooms: [
                        ChatRoom(id: "chat1", clubId: club.id, title: "General", icon: "bubble.left.and.bubble.right.fill", messages: []),
                        ChatRoom(id: "chat2", clubId: club.id, title: "Book Reviews", icon: "book.fill", messages: [])
                    ],
                    upcomingDiscussions: [
                        Discussion(id: "disc1", clubId: club.id, createdBy: "system", title: "Monthly Read", description: "Let's discuss this month's pick!", date: "Saturday", time: "6:00 PM", meetingLink: nil, createdAt: nil)
                    ],
                    posts: [],
                    filters: initialFilters
                )
                self.clubDetail = newDetail
                self.clubDetailData.clubDetails[self.clubId] = newDetail
                self.chatRooms = newDetail.chatRooms
                self.scheduledDiscussions = newDetail.upcomingDiscussions
                self.filter = initialFilters
                self.discussionPost = []
                self.allDiscussionPosts = []
                
                self.isMember = isUserMember(club)
                self.isAdmin = isUserAdmin(club)
            }
            
            DispatchQueue.main.async {
                self.KafkaCollectionView.reloadData()
                self.setupMenu()
            }
            
            // Real-time listener for discussions
            self.discussionsListener?.remove()
            self.discussionsListener = Firestore.firestore().collection("clubs").document(self.clubId).collection("discussions").addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("Error fetching discussions: \(error)")
                    return
                }
                
                let fetchedDiscussions = snapshot?.documents.compactMap { try? $0.data(as: Discussion.self) } ?? []
                
                if !fetchedDiscussions.isEmpty {
                    // Sort descending by creation date (newest first)
                    self.scheduledDiscussions = fetchedDiscussions.sorted(by: { ($0.createdAt ?? "") > ($1.createdAt ?? "") })
                }
                
                DispatchQueue.main.async {
                    self.KafkaCollectionView.reloadData()
                }
            }
            
            // Real-time listener for chat rooms
            self.chatRoomsListener?.remove()
            self.chatRoomsListener = Firestore.firestore().collection("clubs").document(self.clubId).collection("chatrooms").addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("Error fetching chat rooms: \(error)")
                    return
                }
                
                let fetchedChatRooms = snapshot?.documents.compactMap { try? $0.data(as: ChatRoom.self) } ?? []
                
                if !fetchedChatRooms.isEmpty {
                    self.chatRooms = fetchedChatRooms
                }
                
                DispatchQueue.main.async {
                    self.KafkaCollectionView.reloadData()
                }
            }
            
            // Real-time listener for discussion posts
            self.discussionPostsListener?.remove()
            self.discussionPostsListener = Firestore.firestore().collection("clubs").document(self.clubId).collection("discussionPosts").addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("Error fetching discussion posts: \(error)")
                    return
                }
                
                let fetchedPosts = snapshot?.documents.compactMap { try? $0.data(as: DiscussionPost.self) } ?? []
                
                if !fetchedPosts.isEmpty {
                    // Sort descending by creation date/time (if applicable) or default
                    // Assuming they have a createdAt string or we just show them as they are
                    self.allDiscussionPosts = fetchedPosts
                    
                    // Re-apply the current filter
                    let selectedIndex = self.filter.firstIndex(where: { $0.isSelected }) ?? 0
                    let selectedFilter = self.filter[selectedIndex]
                    
                    if selectedFilter.title == "Newest" {
                        self.discussionPost = self.allDiscussionPosts
                    } else if selectedFilter.title == "Popular" {
                        self.discussionPost = self.allDiscussionPosts.sorted { ($0.upvotes ?? 0) > ($1.upvotes ?? 0) }
                    } else {
                        self.discussionPost = self.allDiscussionPosts.filter { post in
                            let query = selectedFilter.title.lowercased()
                            let inTitleOrContent = post.title.lowercased().contains(query) || post.content.lowercased().contains(query)
                            return inTitleOrContent || (post.postType?.lowercased() == query)
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    self.KafkaCollectionView.reloadData()
                }
            }
        }
    }
    

}
extension KafkaViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 6
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section{
        
        case 0: return 1
        case 1: return 1
        case 2: return scheduledDiscussions.count
        case 3: return chatRooms.count
        case 4: return filter.count
        case 5: return discussionPost.count
        default: return 0
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {
        case 0:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "clubHeader_cell",
                for: indexPath
            ) as! ClubHeaderCell
            if let clubDetail = clubDetail {
                cell.configure(with: clubDetail)
            }
            cell.delegate = self
            return cell
        case 1:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "join_cell",
                for: indexPath
            ) as! JoinButtonCollectionViewCell
            cell.configure(isAdmin: isAdmin, isMember: isMember)
            cell.delegate = self
            cell.club = club
            return cell
        case 2:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "discussion_cell",
                for: indexPath
            ) as! ScheduleDiscussionCollectionViewCell
            cell.configure(with: scheduledDiscussions[indexPath.item])
            return cell
        case 3:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "club_cell",
                for: indexPath
            ) as! ChatRoomCollectionViewCell
            cell.configure(with: chatRooms[indexPath.item])
            return cell
        case 4:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "filter_cell", for: indexPath) as! FilterCollectionViewCell
            cell.configure(with: filter[indexPath.item])
            return cell
        case 5:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "post_cell", for: indexPath) as! DiscussionCollectionViewCell
            cell.configure(with: discussionPost[indexPath.item])
            return cell
        default:
            return UICollectionViewCell()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        var headerView: SectionHeaderViewClubDetailCollectionReusableView!
        
        if kind == "header"{
            headerView = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: "detailheader_view",
                for: indexPath
            ) as? SectionHeaderViewClubDetailCollectionReusableView
            
            headerView.delegate = self
            headerView.section = indexPath.section
            
            if indexPath.section == 2{
                headerView.configure(withTitle: "Upcoming Discussions", isAdmin: false)
            }else if indexPath.section == 3{
                headerView.configure(withTitle: "Chat Rooms", isAdmin: isAdmin)
            }else if indexPath.section == 4{
                headerView.configure(withTitle: "Discussion", isAdmin: true)
            }
            
        }
        return headerView
    }
}

// MARK: - ClubHeaderCellDelegate
extension KafkaViewController: ClubHeaderCellDelegate {
    func didTapMemberList() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "MemberListVC") as! MemberListVC

        vc.members = club?.members ?? []
        vc.clubName = club?.name ?? "Members"
        vc.isAdmin = isAdmin
        vc.clubData = clubData
        vc.clubId = clubId

        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .automatic

        present(nav, animated: true)
    }
}

// MARK: - SectionHeaderDelegate
extension KafkaViewController: SectionHeaderDelegate {
    func didTapActionButton(inSection section: Int) {
        if section == 4 {
            // Discussion section "+ New" tapped
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "DiscussionViewController") as! DiscussionViewController
            vc.delegate = self  // pass data back via delegate
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .automatic
            present(nav, animated: true)
        }
        if section == 3{
            // Chatroom section "+ New" tapped
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "CreateChatRoomViewController") as! CreateNewChatRoomViewController
            vc.delegate = self  // pass data back via delegate
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .automatic
            present(nav, animated: true)
            
        }

    }
}

// MARK: - NewDiscussionDelegate
extension KafkaViewController: NewDiscussionDelegate, NewChatRoomDelegate, NewScheduledDiscussionDelegate{
    func didCreateDiscussion(_ post: DiscussionPost) {
        clubDetailData.addDiscussionPost(post, toClub: clubId)
        
        do {
            try Firestore.firestore().collection("clubs").document(clubId).collection("discussionPosts").document(post.id).setData(from: post)
        } catch {
            print("Error saving discussion post to Firebase: \(error)")
        }
    }
    func didCreateChatRoom(_ chatRoom: ChatRoom) {
        var mutableRoom = chatRoom
        mutableRoom.clubId = clubId
        clubDetailData.addChatRoom(mutableRoom, toClub: clubId)
        
        do {
            try Firestore.firestore().collection("clubs").document(clubId).collection("chatrooms").document(mutableRoom.id).setData(from: mutableRoom)
        } catch {
            print("Error saving chatroom to Firebase: \(error)")
        }
    }
    func didCreateScheduledDiscussion(_ discussion: Discussion) {
        clubDetailData.addScheduledDiscussion(discussion, toClub: clubId)

        do {
            try Firestore.firestore().collection("clubs").document(clubId).collection("discussions").document(discussion.id).setData(from: discussion)
        } catch {
            print("Error saving discussion to Firebase: \(error)")
        }
        
        // The snapshot listener (discussionsListener) will automatically pick up the new discussion 
        // and update the scheduledDiscussions array + collection view section.
    }
}

// MARK: - UICollectionViewDelegate
extension KafkaViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        if indexPath.section == 4 {
            let selectedFilter = filter[indexPath.item]
            
            // Toggle selection state
            for i in 0..<filter.count {
                filter[i].isSelected = (i == indexPath.item)
            }
            
            // Filter posts
            if selectedFilter.title == "Newest" {
                discussionPost = allDiscussionPosts
            } else if selectedFilter.title == "Popular" {
                discussionPost = allDiscussionPosts.sorted { ($0.upvotes ?? 0) > ($1.upvotes ?? 0) }
            } else {
                discussionPost = allDiscussionPosts.filter { post in
                    let query = selectedFilter.title.lowercased()
                    let inTitleOrContent = post.title.lowercased().contains(query) || post.content.lowercased().contains(query)
                    return inTitleOrContent || (post.postType?.lowercased() == query)
                }
            }
            
            // Reload Section 4 (filters) and Section 5 (posts)
            collectionView.reloadSections(IndexSet(integersIn: 4...5))
        }
        
        if indexPath.section == 2 {
            let discussion = scheduledDiscussions[indexPath.item]
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "SDViewController") as! SDViewController
            vc.discussion = discussion
            vc.clubDetailData = clubDetailData
            vc.isMember = isMember
            
            navigationController?.pushViewController(vc, animated: true)
        }
        
        if indexPath.section == 3 {
            let chatRoom = chatRooms[indexPath.item]
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "ChatRoomMessageVC") as! ChatRoomViewController
            vc.chatRoom = chatRoom
            vc.clubId = self.clubId
            vc.hidesBottomBarWhenPushed = true
            
            navigationController?.pushViewController(vc, animated: true)
        }
        
        if indexPath.section == 5 {
            let selectedPost = discussionPost[indexPath.item]
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "DiscussionDetailViewController") as! DiscussionDetailViewController
            vc.post = selectedPost
            vc.clubId = self.clubId
            vc.comments = selectedPost.comments ?? []
            
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}

extension KafkaViewController{
    
    func generateLayout() -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout { [weak self] sectionIndex, environment -> NSCollectionLayoutSection? in
            guard let self = self else { return nil }
            
            let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(55))
            let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: "header", alignment: .topLeading)
            
            switch sectionIndex {
            case 0:
                let section = self.generateClubHeaderLayout()
                return section
                
            case 1:
                let section = self.generateChatRoomLayout()
//                section.boundarySupplementaryItems = [header]
                return section
            
            case 2:
                // For example, section 1 = schedule/discussions
                let section = self.generateScheduleDiscussionLayout()
                section.boundarySupplementaryItems = [header]
                return section
                
            case 3:
                // For example, section 0 = chat rooms
                let section = self.generateChatRoomLayout()
                section.boundarySupplementaryItems = [header]
                return section
                

            case 4:
                let section = self.generateFilterLayout()
                section.boundarySupplementaryItems = [header]
                return section
            case 5:
                let section = self.generatePostLayout()
//                section.boundarySupplementaryItems = [header]
                return section
            default:
                // Default fallback layout
                return self.generateChatRoomLayout()
            }
        }
        
        return layout
    }
    func generateJoinButtonLayout() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .fractionalHeight(1.0/3.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(100))
        
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, repeatingSubitem: item, count: 1)
        
        let section = NSCollectionLayoutSection(group: group)
        
        
        return section
    }

    func generateChatRoomLayout() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .fractionalHeight(1.0/3.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(220))
        
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, repeatingSubitem: item, count: 3)
        
        let section = NSCollectionLayoutSection(group: group)
        
        
        return section
    }
    
    func generateScheduleDiscussionLayout() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .absolute(300),
            heightDimension: .absolute(180)
        )
        
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, repeatingSubitem: item, count: 1)
        
        let section = NSCollectionLayoutSection(group: group)
        
        section.interGroupSpacing = 14
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 10,
            leading: 16,
            bottom: 10,
            trailing: 16
        )
        section.orthogonalScrollingBehavior = .groupPaging
        
        return section
    }
    
    func generateFilterLayout() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .absolute(80),
            heightDimension: .absolute(40)
        )
        
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, repeatingSubitem: item, count: 1)
        
        let section = NSCollectionLayoutSection(group: group)
        
        section.interGroupSpacing = 14
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 10,
            leading: 16,
            bottom: 10,
            trailing: 16
        )
        section.orthogonalScrollingBehavior = .continuous
        
        return section
    }
    
    func generatePostLayout() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(130))
        
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, repeatingSubitem: item, count: 1)
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 12
        section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0)
        
        return section
    }
    
    func generateClubHeaderLayout() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(340))
        
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, repeatingSubitem: item, count: 1)
        
        let section = NSCollectionLayoutSection(group: group)
        
        
        return section
        
        
    }
}

// MARK: - JoinDelegate
extension KafkaViewController: JoinDelegate {
    func didTapJoin(clubId: String) {
        if isAdmin {
            // Admin tapped "Schedule Discussion" → present ScheduleDiscussionViewController
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "ScheduleDiscussionViewController") as! ScheduleDiscussionViewController
            vc.delegate = self
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .automatic
            present(nav, animated: true)
        } else {
            clubData.joinClub(clubId: clubId)

            // Optimistically update the local club object so UI updates instantly
            let newMember = ClubMember(
                clubId: clubId,
                userId: currentUserId,
                role: "member",
                joinedAt: "\(Date())",
                fullName: "You" // Temporary placeholder until backend syncs
            )
            
            if club?.members != nil {
                club?.members?.append(newMember)
            } else {
                club?.members = [newMember]
            }

            // Reload data so UI reflects membership
            loadData()
            setupMenu()
        }
    }
    
    func setupMenu() {
        if isAdmin {
            let deleteAction = UIAction(title: "Delete Club", attributes: .destructive) { [weak self] _ in
                guard let self = self else { return }
                let alert = UIAlertController(title: "Delete Club", message: "Are you sure you want to delete this club?", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
                    self.clubData.deleteClub(clubId: self.clubId)
                    self.navigationController?.popViewController(animated: true)
                })
                self.present(alert, animated: true)
            }
            let menu = UIMenu(title: "", children: [deleteAction])
            threeDots.menu = menu
        } else if isMember {
            let leaveAction = UIAction(title: "Leave Club", attributes: .destructive) { [weak self] _ in
                guard let self = self else { return }
                let alert = UIAlertController(title: "Leave Club", message: "Are you sure you want to leave this club?", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                alert.addAction(UIAlertAction(title: "Leave", style: .destructive) { _ in
                    self.clubData.leaveClub(clubId: self.clubId)
                    
                    // Optimistically update local club
                    self.club?.members?.removeAll(where: { $0.userId == currentUserId })
                    
                    self.loadData()
                    self.setupMenu()
                })
                self.present(alert, animated: true)
            }
            let menu = UIMenu(title: "", children: [leaveAction])
            threeDots.menu = menu
        }
    }
}
