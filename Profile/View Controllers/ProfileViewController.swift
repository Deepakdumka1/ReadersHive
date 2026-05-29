import UIKit
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

class ProfileViewController: UIViewController {
    
    @IBOutlet weak var profileCollectionView: UICollectionView!
    
    var profile: Profile?
    var posts: [FeedPost] = []
    private var listener: ListenerRegistration?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        registerCells()
        
        setupUI()
        
        fetchCurrentProfile()
        fetchUserPosts()
    }
    
    private func setupUI() {
        NSLayoutConstraint.activate([
            profileCollectionView.topAnchor.constraint(equalTo: view.topAnchor),
            profileCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            profileCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            profileCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func fetchCurrentProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        // Real-time listener for profile counts (followers/following)
        Firestore.firestore().collection("profiles").document(uid).addSnapshotListener { [weak self] snapshot, _ in
            if let profile = try? snapshot?.data(as: Profile.self) {
                DispatchQueue.main.async {
                    self?.profile = profile
                    self?.profileCollectionView.reloadData()
                }
            }
        }
    }
    
    private func fetchUserPosts() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        // Real-time listener for own posts
        Firestore.firestore().collection("posts")
            .whereField("userId", isEqualTo: uid)
            .addSnapshotListener { [weak self] snapshot, _ in
                let fetched = snapshot?.documents.compactMap { try? $0.data(as: FeedPost.self) } ?? []
                let sortedPosts = fetched.sorted {
                    ($0.createdAt ?? Date.distantPast) > ($1.createdAt ?? Date.distantPast)
                }
                DispatchQueue.main.async {
                    self?.posts = sortedPosts
                    self?.profileCollectionView.reloadData()
                }
            }
    }
    
    private func setupCollectionView() {
        profileCollectionView.collectionViewLayout = createCompositionalLayout()
        profileCollectionView.delegate = self
        profileCollectionView.dataSource = self
    }
    
    private func createCompositionalLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { (sectionIndex, _) -> NSCollectionLayoutSection? in
            if sectionIndex == 0 {
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(200))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: itemSize, subitems: [NSCollectionLayoutItem(layoutSize: itemSize)])
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
                return section
            } else {
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .absolute(260))
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(260))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(50)), elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
                section.boundarySupplementaryItems = [header]
                return section
            }
        }
    }
    
    private func registerCells() {
        profileCollectionView.register(UINib(nibName: "ProfileCardCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "profileCell")
        profileCollectionView.register(UINib(nibName: "PostsCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "postCell")
        profileCollectionView.register(UINib(nibName: "MyPostsHeaderCell", bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "postHeaderCell")
    }
}

extension ProfileViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int { return 2 }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return section == 0 ? 1 : posts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "profileCell", for: indexPath) as! ProfileCardCollectionViewCell
            if let p = profile {
                cell.configure(name: p.fullName, username: p.username, followers: p.followers?.count ?? 0, following: p.following?.count ?? 0, bio: p.bio ?? "", imageName: p.avatarUrl)
            }
            cell.delegate = self
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "postCell", for: indexPath) as! PostsCollectionViewCell
            let post = posts[indexPath.item]
            cell.configure(with: post)
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "postHeaderCell", for: indexPath) as! MyPostsHeaderCell
        header.configure(title: "My Posts")
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let section = Section(rawValue: indexPath.section), section == .posts else { return }
        
        let post = self.posts[indexPath.row]
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

import FirebaseStorage

extension ProfileViewController: ProfileCardDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
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
    
    func didTapProfileImage() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        guard let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage else { return }
        uploadProfileImage(image)
    }
    
    private func uploadProfileImage(_ image: UIImage) {
        guard let uid = Auth.auth().currentUser?.uid,
              let imageData = image.jpegData(compressionQuality: 0.7) else { return }
        
        let storageRef = Storage.storage().reference().child("profile_images/\(uid).jpg")
        
        // Show a simple loading indicator if you have one, or just print for now
        print("Uploading profile image...")
        
        storageRef.putData(imageData, metadata: nil) { [weak self] _, error in
            if let error = error {
                print("❌ Error uploading image: \(error.localizedDescription)")
                return
            }
            
            storageRef.downloadURL { url, _ in
                guard let url = url else { return }
                self?.updateProfileImageUrl(url.absoluteString)
            }
        }
    }
    
    private func updateProfileImageUrl(_ urlString: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        // Use avatar_url to match the Profile model's CodingKeys
        Firestore.firestore().collection("profiles").document(uid).updateData([
            "avatar_url": urlString
        ]) { error in
            if let error = error {
                print("Error updating profile data: \(error.localizedDescription)")
            } else {
                print("Profile image updated successfully!")
            }
        }
    }
}

enum Section: Int, CaseIterable {
    case profileCard = 0
    case posts = 1
}
