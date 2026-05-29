//
//  MyPostsViewController.swift
//  Club
//
//  Created by GEU on 08/04/26.
//

import UIKit

class MyPostsViewController: UIViewController {
    
    private enum PostSortOption {
        case newest, oldest, mostLiked
    }

    private var currentPostSort: PostSortOption = .newest

    @IBOutlet weak var postsCollectionView: UICollectionView!
    @IBOutlet weak var postsMenuButton: UIBarButtonItem!
    
    
    //Load data
    var posts: [FeedPost] = []
    var selectedIndex: Int = 0
    private var hasScrolledToInitialIndex = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        setupMenuButton()
        registerCells()
    }
    
    private func setupMenuButton() {
        
        let filterNewest = UIAction(
            title: "Newest First",
            state: currentPostSort == .newest ? .on : .off
        ) { [weak self] _ in
            guard let self = self else { return }
            self.currentPostSort = .newest
            self.posts.sort { $0.time > $1.time }
            self.postsCollectionView.reloadData()
            self.setupMenuButton()
        }
        
        let filterOldest = UIAction(
            title: "Oldest First",
            state: currentPostSort == .oldest ? .on : .off
        ) { [weak self] _ in
            guard let self = self else { return }
            self.currentPostSort = .oldest
            self.posts.sort { $0.time < $1.time }
            self.postsCollectionView.reloadData()
            self.setupMenuButton()
        }
        
        let filterLiked = UIAction(
            title: "Most Liked",
            state: currentPostSort == .mostLiked ? .on : .off
        ) { [weak self] _ in
            guard let self = self else { return }
            self.currentPostSort = .mostLiked
            self.posts.sort { $0.likeCount > $1.likeCount }
            self.postsCollectionView.reloadData()
            self.setupMenuButton()
        }
        
        let menu = UIMenu(title: "", children: [
            filterNewest,
            filterOldest,
            filterLiked
        ])
        
        postsMenuButton.menu = menu
    }
    
    
    //Load and scroll directly to user selected posts
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !hasScrolledToInitialIndex && !posts.isEmpty && selectedIndex < posts.count {
            let indexPath = IndexPath(item: selectedIndex, section: 0)
            postsCollectionView.scrollToItem(at: indexPath, at: .top, animated: false)
            hasScrolledToInitialIndex = true
        }
    }

    private func registerCells() {
        let nib = UINib(nibName: "UserPostsCollectionViewCell", bundle: nil)
        postsCollectionView.register(nib, forCellWithReuseIdentifier: "UserPostsCollectionViewCell")
    }
    
    //Registering collection view
    private func setupCollectionView() {
        NSLayoutConstraint.activate([
            postsCollectionView.topAnchor.constraint(equalTo: view.topAnchor),
            postsCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            postsCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            postsCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        postsCollectionView.dataSource = self
        postsCollectionView.delegate = self
        postsCollectionView.collectionViewLayout = createLayout()
    }
    
    
    //Generate layout for user posts
    private func createLayout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(580)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(580)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 16
        section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 0, bottom: 16, trailing: 0)
        
        return UICollectionViewCompositionalLayout(section: section)
    }
}



//MARK: - UICollectionViewDataSource & Delegate
extension MyPostsViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "UserPostsCollectionViewCell", for: indexPath) as? UserPostsCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        let post = posts[indexPath.item]
        cell.configure(with: post)
        cell.delegate = self
        
        return cell
    }
}



extension MyPostsViewController: UserPostsCellDelegate {
    func didTapComment(on cell: UserPostsCollectionViewCell) {
        let commentsVC = CommentsViewController()
        commentsVC.modalPresentationStyle = .pageSheet
        
        if let sheet = commentsVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        
        present(commentsVC, animated: true)
    }
    
    func didTapEdit(on cell: UserPostsCollectionViewCell) {
        let alert = UIAlertController(title: "Edit Post", message: "Editing functionality is under construction.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func didTapShare(on cell: UserPostsCollectionViewCell) {
        guard let indexPath = postsCollectionView.indexPath(for: cell) else { return }
        let post = posts[indexPath.item]
        
        var activityItems: [Any] = [post.content]
        if let imageName = post.postImage, let image = UIImage(named: imageName) {
            activityItems.append(image)
        }
        
        let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        
        // iPad support
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = cell.optionsButton
            popover.sourceRect = cell.optionsButton.bounds
        }
        
        present(activityVC, animated: true)
    }
    
    func didTapDelete(on cell: UserPostsCollectionViewCell) {
        guard let indexPath = postsCollectionView.indexPath(for: cell) else { return }
        
        let alert = UIAlertController(title: "Delete Post", message: "Are you sure you want to delete this post?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.posts.remove(at: indexPath.item)
            self?.postsCollectionView.deleteItems(at: [indexPath])
        })
        
        present(alert, animated: true)
    }
}
