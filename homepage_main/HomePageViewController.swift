//
//  ViewController.swift
//  homepage_main
//
//  Created by Deepak Dumka on 13/02/26.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
enum HomeSection {
    case post(FeedPost)
    case suggested
    case trending
}
class HomePageViewController: UIViewController {
    var sections: [HomeSection] = []
    var book: TrendingData!
    var trending: [TrendingBook] = []
    
    var feedData: FeedData!
    var posts: [FeedPost] = []
    
    var suggestedData: SuggestedData!
    var suggestedUsers: [SuggestedUser] = []
    @IBOutlet weak var createPostButton: UIButton!
    
    // Add constraints to hold the button in place
    private var createPostButtonBottomConstraint: NSLayoutConstraint?
    private var createPostButtonTrailingConstraint: NSLayoutConstraint?

    
    @IBOutlet weak var BookCollectionView: UICollectionView!
    
    @IBAction func profileButtonTapped(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "homeToProfileSegue", sender: self)
    }
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        loadData()
        registerCells()
        setupPostButton()
        setupCollectionView()

    }
    private func setupPostButton() {
        createPostButton.translatesAutoresizingMaskIntoConstraints = false
        
        // HIG recommended size for primary actions is around 50-60 points
        let buttonSize: CGFloat = 60
        
        NSLayoutConstraint.activate([
            createPostButton.widthAnchor.constraint(equalToConstant: buttonSize),
            createPostButton.heightAnchor.constraint(equalToConstant: buttonSize),
            createPostButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            createPostButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
        
        createPostButton.configuration?.cornerStyle = .capsule
        // Remove content insets if we want it to be a perfect circle/square
        createPostButton.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        
        // Ensure the button stays on top of the collection view
        view.bringSubviewToFront(createPostButton)
    }
    
    private func setupCollectionView() {
        NSLayoutConstraint.activate([
            BookCollectionView.topAnchor.constraint(equalTo: view.topAnchor),
            BookCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            BookCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            BookCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        //        BookCollectionView.contentInsetAdjustmentBehavior = .never
                
                BookCollectionView.setCollectionViewLayout(generateLayout(), animated: false)
                BookCollectionView.dataSource = self
                BookCollectionView.delegate = self
                BookCollectionView.backgroundColor = .systemBackground
    }
    func showBookPresentation(for book: Book) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let vc = storyboard.instantiateViewController(withIdentifier: "BookPresentationViewController") as? BookPresentationViewController else { return }
        
        vc.book = book
        vc.bookshelfData = AppDependencies.shared.bookshelfData
        self.present(vc, animated: true)
    }
    
    @objc func closePopup(_ sender: UITapGestureRecognizer) {
        sender.view?.removeFromSuperview()
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "homeToProfileSegue" {
            segue.destination.hidesBottomBarWhenPushed = true
        }
        if segue.identifier == "createPostViewController" {
              let vc = segue.destination as! createPostViewController
              vc.delegate = self   //  FIX HERE
            
            segue.destination.hidesBottomBarWhenPushed = true

          }
    }
    
    
    func registerCells() {
        BookCollectionView.register(UINib(nibName: "TrendingBookCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "TrendingBookCollectionViewCell")
        BookCollectionView.register(UINib(nibName: "SuggestedUserCell", bundle: nil), forCellWithReuseIdentifier: "SuggestedUserCell")
        BookCollectionView.register(UINib(nibName: "FeedRichPostCell", bundle: nil), forCellWithReuseIdentifier: "FeedRichPostCell")
        BookCollectionView.register(UINib(nibName: "FeedRichPostCellWithImage", bundle: nil), forCellWithReuseIdentifier: "FeedRichPostCellWithImage")
        
        BookCollectionView.register(
            UINib(nibName: "TrendingSectionCell", bundle: nil),
            forCellWithReuseIdentifier: "TrendingSectionCell"
        )
        
        BookCollectionView.register(
            UINib(nibName: "SuggestedSectionCell", bundle: nil),
            forCellWithReuseIdentifier: "SuggestedSectionCell"
        )
        
        BookCollectionView.register(
            UINib(nibName: "SectionHeaderView", bundle: nil),
            forSupplementaryViewOfKind: "header",
            withReuseIdentifier: "SectionHeaderView"
        )
    }
    
    func loadData() {
        trending = book.books(for: .classics)
        
        feedData.load { [weak self] posts in
            self?.posts = posts
            self?.buildSections()
            self?.BookCollectionView.reloadData()
        }
        
        suggestedData.load { [weak self] users in
            self?.suggestedUsers = users
            self?.buildSections()
            self?.BookCollectionView.reloadData()
        }
    }
    func buildSections() {
        sections.removeAll()
        sections.append(.trending)
        for (index, post) in posts.enumerated() {
            sections.append(.post(post))
            
            //  First check suggested (higher priority)
//            if (index + 1) % 4 == 0 {
//                sections.append(.suggested)
//            }
            //  Then trending
            
            }
        }
    }
//    func buildSections() {
//        sections = posts.map { HomeSection.post($0) }
//    }


extension HomePageViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Add navigation logic here if needed, similar to BookHive
    }
}

// MARK: - UICollectionViewDataSource
extension HomePageViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        sections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let sectionType = sections[indexPath.section]
        
        switch sectionType {
            
        case .post(let post):
            if post.localImage != nil || post.postImage != nil {
                
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "FeedRichPostCellWithImage",
                    for: indexPath
                ) as! FeedRichPostCellWithImage
                
                cell.configureCell(with: post, delegate: self)
                
                //  BOOK TAP
                cell.onBookTapped = { [weak self] in
                    guard let title = post.bookTitle else { return }
                    let book = Book(id: UUID().uuidString, title: title, author: post.bookAuthor ?? "Unknown", coverImageURL: post.bookCoverImage ?? "", description: "")
                    self?.showBookPresentation(for: book)
                }
                
                return cell
                
            } else {
                
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "FeedRichPostCell",
                    for: indexPath
                ) as! FeedRichPostCell
                
                cell.configureCell(with: post, delegate: self)
                
                // BOOK TAP
                cell.onBookTapped = { [weak self] in
                    guard let title = post.bookTitle else { return }
                    let book = Book(id: UUID().uuidString, title: title, author: post.bookAuthor ?? "Unknown", coverImageURL: post.bookCoverImage ?? "", description: "")
                    self?.showBookPresentation(for: book)
                }
                
                return cell
            }

//            
        case .trending:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "TrendingSectionCell",
                for: indexPath
            ) as! TrendingSectionCell
            
            cell.configure(with: trending)
            cell.delegate = self
            return cell
            
//        case .suggested:
//            let cell = collectionView.dequeueReusableCell(
//                withReuseIdentifier: "SuggestedSectionCell",
//                for: indexPath
//            ) as! SuggestedSectionCell
//            
//            cell.configure(with: suggestedUsers, delegate: self)
//            return cell
        default:
            return UICollectionViewCell()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let headerView = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: "SectionHeaderView",
            for: indexPath
        ) as! SectionHeaderView
        let sectionType = sections[indexPath.section]
        
        switch sectionType {
        case .trending:
            headerView.configure(withTitle: "Trending Books")
        
        case .post:
            if indexPath.section == 1 {
                headerView.configure(withTitle: "New Posts")
            } else {
                headerView.configure(withTitle: "")
            }
            
//        case .suggested:
//            headerView.configure(withTitle: "Suggested for you")
            
        default:
            headerView.configure(withTitle: "")
        }
        
        return headerView
    }
}

// MARK: - Compositional Layout
extension HomePageViewController {
    
    func generateLayout() -> UICollectionViewLayout {
        
        return UICollectionViewCompositionalLayout { [weak self] (sectionIndex, _) -> NSCollectionLayoutSection? in
            
            guard let self = self else { return nil }
            
            let sectionType = self.sections[sectionIndex]
            
            
            let headerSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(50)
            )
            
            
            let header = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: "header", //  SAME STRING
                alignment: .top
            )
            header.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
            
            switch sectionType {
                
            case .post:
                let section = self.generatePostSection()
                if sectionIndex == 1 {
                    section.boundarySupplementaryItems = [header]
                }
                return section
                
            case .trending:
                header.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
                let section = self.generateBookSection()
                section.boundarySupplementaryItems = [header]
                return section
                
//            case .suggested:
//                let section = self.generateSuggestedSection()
//                section.boundarySupplementaryItems = [header]
//                return section
            default:
                return nil
            }
        }
    }
    func generateBookSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(240) //  important
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            repeatingSubitem: item,
            count: 1
        )
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 20
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 0,
            leading: 20,
            bottom: 16,
            trailing: 20
        )
        section.orthogonalScrollingBehavior = .continuous
        
        return section
    }
    
    func generateSuggestedSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(220)
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            repeatingSubitem: item,
            count: 1
        )
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 16
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 0,
            leading: 20,
            bottom: 24,
            trailing: 20
        )
        section.orthogonalScrollingBehavior = .continuous
        
        return section
    }
    
    func generatePostSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(250)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(250)
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitems: [item]
        )
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 16
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 16,
            leading: 0,
            bottom: 16,
            trailing: 0
        )
        
        return section
    }
    
}

// MARK: - Feed & Suggested Interaction Delegates
extension HomePageViewController: FeedRichPostCellDelegate, FeedRichPostCellWithImageDelegate, SuggestedUserCellDelegate {
    
    // Shared Navigation
    func didTapUser(userId: String) {
        navigateToProfile(userId: userId)
    }

    // Text Post Actions
    func didTapLike(on cell: FeedRichPostCell) {
        guard let indexPath = BookCollectionView.indexPath(for: cell) else { return }
        let sectionType = sections[indexPath.section]
        guard case .post(let post) = sectionType else { return }
        
        feedData.toggleLike(for: post.id)
        posts = feedData.posts
        buildSections()
        
        if let updatedCell = BookCollectionView.cellForItem(at: indexPath) as? FeedRichPostCell {
            if let updatedPost = posts.first(where: { $0.id == post.id }) {
                updatedCell.configureCell(with: updatedPost, delegate: self)
            }
        }
    }
    
    func didTapShare(on cell: FeedRichPostCell) {
        guard let indexPath = BookCollectionView.indexPath(for: cell) else { return }
        let sectionType = sections[indexPath.section]
        guard case .post(let post) = sectionType else { return }
        
        let shareText = "Check out this post by \(post.name):\n\"\(post.content)\""
        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = cell.shareIconImageView
            popover.sourceRect = cell.shareIconImageView.bounds
        }
        present(activityVC, animated: true)
    }
    
    func didTapComment(on cell: FeedRichPostCell) {
        guard let indexPath = BookCollectionView.indexPath(for: cell) else { return }
        let sectionType = sections[indexPath.section]
        guard case .post(let post) = sectionType else { return }
        
        let commentsVC = CommentsViewController()
        commentsVC.post = post
        commentsVC.feedData = feedData
        commentsVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(commentsVC, animated: true)
    }

    // Image Post Actions
    func didTapLike(on cell: FeedRichPostCellWithImage) {
        guard let indexPath = BookCollectionView.indexPath(for: cell) else { return }
        let sectionType = sections[indexPath.section]
        guard case .post(let post) = sectionType else { return }
        
        feedData.toggleLike(for: post.id)
        posts = feedData.posts
        buildSections()
        
        if let updatedCell = BookCollectionView.cellForItem(at: indexPath) as? FeedRichPostCellWithImage {
            if let updatedPost = posts.first(where: { $0.id == post.id }) {
                updatedCell.configureCell(with: updatedPost, delegate: self)
            }
        }
    }
    
    func didTapShare(on cell: FeedRichPostCellWithImage) {
        guard let indexPath = BookCollectionView.indexPath(for: cell) else { return }
        let sectionType = sections[indexPath.section]
        guard case .post(let post) = sectionType else { return }
        let shareText = "Check out this post with image by \(post.name):\n\"\(post.content)\""
        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = cell.shareIconImageView
            popover.sourceRect = cell.shareIconImageView.bounds
        }
        present(activityVC, animated: true)
    }
    
    func didTapComment(on cell: FeedRichPostCellWithImage) {
        guard let indexPath = BookCollectionView.indexPath(for: cell) else { return }
        let sectionType = sections[indexPath.section]
        guard case .post(let post) = sectionType else { return }
        
        let commentsVC = CommentsViewController()
        commentsVC.post = post
        commentsVC.feedData = feedData
        commentsVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(commentsVC, animated: true)
    }

    // Suggested User Actions
    func didTapFollow(userId: String) {
        suggestedData.toggleFollow(for: userId)
    }
    
    func didTapClose(userId: String) {
        suggestedData.removeUser(for: userId)
        suggestedUsers = suggestedData.users
        buildSections()
        BookCollectionView.reloadData()
    }
}

// MARK: - Profile Navigation Helper
extension HomePageViewController {
    func navigateToProfile(userId: String) {
        if userId == Auth.auth().currentUser?.uid {
            performSegue(withIdentifier: "homeToProfileSegue", sender: self)
        } else {
            // Navigate to Other User Profile
            let db = Firestore.firestore()
            db.collection("profiles").document(userId).getDocument { [weak self] (snapshot: DocumentSnapshot?, error: Error?) in
                guard let self = self, let snapshot = snapshot, snapshot.exists else { return }
                
                if let profile = try? snapshot.data(as: Profile.self) {
                    DispatchQueue.main.async {
                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                        if let vc = storyboard.instantiateViewController(withIdentifier: "OtherUserProfileViewController") as? OtherUserProfileViewController {
                            vc.profile = profile
                            vc.hidesBottomBarWhenPushed = true
                            self.navigationController?.pushViewController(vc, animated: true)
                        }
                    }
                }
            }
        }
    }
}

extension HomePageViewController: CreatePostDelegate {
    
    func didCreatePost(_ post: FeedPost) {
        print("POST RECEIVED")
        
        // Save to Firebase
        feedData.savePost(post)
        
        // UI will be updated automatically by the SnapshotListener in FeedData
    }
}

extension HomePageViewController: TrendingSectionCellDelegate {
    func didTapTrendingBook(_ trendingBook: TrendingBook) {
        let book = Book(id: trendingBook.id, title: trendingBook.title, author: trendingBook.author, coverImageURL: trendingBook.coverImage, description: "Trending Category: \(trendingBook.category.rawValue)")
        showBookPresentation(for: book)
    }
}
