 //
//  FollowingViewController.swift
//  Club
//
//  Created by GEU on 24/03/26.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class FollowingViewController: UIViewController {
    
    private enum SortOption {
           case newest, oldest, alphabetical
       }
       
       private var currentSort: SortOption = .newest
    
    //Helper function
    private func makeConversation(from profile: Profile, id: String) -> Conversation {
        return Conversation(
            id: id,
            otherUserId: profile.userId,
            otherUserName: profile.fullName,
            avatarImage: profile.avatarUrl ?? "",
            lastMessage: "",
            lastMessageTimestamp: Date()
        )
    }
    
    private func openChat(with profile: Profile) {
          let storyboard = UIStoryboard(name: "Main", bundle: nil)
          guard let vc = storyboard.instantiateViewController(withIdentifier: "ChatViewController") as? ChatViewController else { return }
          
          guard let currentUserId = Auth.auth().currentUser?.uid else { return }
          let conversationId = [currentUserId, profile.userId].sorted().joined(separator: "_")
          vc.conversation = makeConversation(from: profile, id: conversationId)
          vc.hidesBottomBarWhenPushed = true
          navigationController?.pushViewController(vc, animated: true)
      }
    
    @IBOutlet weak var showMenuButton: UIBarButtonItem!
    @IBOutlet weak var followingTableView: UITableView!
    
    private let searchBar = UISearchBar()
    
    var userProfile: Profile?
    var listType: FollowType = .following
    var conversation: Conversation?
    
    private var dataList: [Profile] = []
    private var filteredDataList: [Profile] = []
    
    // Cached for O(1) lookup
    private var followingSet: Set<String> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupSearchBar()
        setupUI()
        registerCells()
        setupMenuButton()
        
        if userProfile?.userId != Auth.auth().currentUser?.uid {
            navigationItem.rightBarButtonItem = nil
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
    }
    
    // SEARCH BAR SETUP
    private func setupSearchBar() {
        searchBar.searchBarStyle = .minimal
        searchBar.placeholder = "People"
        searchBar.delegate = self
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        
        let micButton = UIButton(type: .system)
        micButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        micButton.tintColor = .gray
        
        searchBar.searchTextField.rightView = micButton
        searchBar.searchTextField.rightViewMode = .always
        
        view.addSubview(searchBar)
        
        NSLayoutConstraint.activate([
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            searchBar.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupUI() {
        
        followingTableView.separatorStyle = .none
        followingTableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            followingTableView.topAnchor.constraint(equalTo: view.topAnchor),
            followingTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            followingTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            followingTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        followingTableView.dataSource = self
        followingTableView.delegate = self
        followingTableView.rowHeight = 80
    }
    
    private func registerCells() {
        let nib = UINib(nibName: "UserTableViewCell", bundle: nil)
        followingTableView.register(nib, forCellReuseIdentifier: "UserTableViewCell")
    }
    
    private func setupMenuButton() {
        
        let filterNewest = UIAction(
            title: "Newest First",
            state: currentSort == .newest ? .on : .off
        ) { [weak self] _ in
            guard let self = self else { return }
            self.currentSort = .newest
            self.filteredDataList = self.dataList
            self.followingTableView.reloadData()
            self.setupMenuButton()
        }
        
        let filterOldest = UIAction(
            title: "Oldest First",
            state: currentSort == .oldest ? .on : .off
        ) { [weak self] _ in
            guard let self = self else { return }
            self.currentSort = .oldest
            self.filteredDataList = self.dataList.reversed()
            self.followingTableView.reloadData()
            self.setupMenuButton()
        }
        
        let filterAlpha = UIAction(
            title: "Alphabetical",
            state: currentSort == .alphabetical ? .on : .off
        ) { [weak self] _ in
            guard let self = self else { return }
            self.currentSort = .alphabetical
            self.filteredDataList = self.dataList.sorted {
                $0.fullName.localizedCaseInsensitiveCompare($1.fullName) == .orderedAscending
            }
            self.followingTableView.reloadData()
            self.setupMenuButton()
        }
        
        let menu = UIMenu(title: "", children: [
            filterNewest,
            filterOldest,
            filterAlpha
        ])
        
        showMenuButton.menu = menu
    }
    
    
    private func loadData() {
        guard let userId = userProfile?.userId else { return }
        
        let currentListType = self.listType
        let db = Firestore.firestore()
        db.collection("profiles").document(userId).getDocument { [weak self] snapshot, _ in
            guard let self = self, let data = snapshot?.data() else { return }
            
            let ids: [String]
            if currentListType == .followers {
                ids = data["followers"] as? [String] ?? []
            } else {
                ids = data["following"] as? [String] ?? []
            }
            
            if ids.isEmpty {
                self.dataList = []
                self.filteredDataList = []
                self.followingSet = []
                self.followingTableView.reloadData()
                return
            }
            
            // Firestore 'in' limit is 10, so process in chunks
            let chunks = stride(from: 0, to: ids.count, by: 10).map {
                Array(ids[$0..<min($0 + 10, ids.count)])
            }
            
            var fetchedProfiles: [Profile] = []
            let group = DispatchGroup()
            
            for chunk in chunks {
                group.enter()
                db.collection("profiles").whereField(FieldPath.documentID(), in: chunk).getDocuments { snap, _ in
                    let profiles = snap?.documents.compactMap { try? $0.data(as: Profile.self) } ?? []
                    fetchedProfiles.append(contentsOf: profiles)
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                self.dataList = fetchedProfiles
                self.filteredDataList = self.dataList
                // Store following IDs in the set to easily update button UI (if needed)
                self.followingSet = Set(fetchedProfiles.map { $0.userId })
                self.followingTableView.reloadData()
            }
        }
    }
}



// MARK: - UISearchBarDelegate
extension FollowingViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let query = searchText.lowercased()
        
        if query.isEmpty {
            filteredDataList = dataList
        } else {
            filteredDataList = dataList.filter {
                ($0.username + $0.fullName).lowercased().contains(query)
            }
        }
        
        followingTableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}



// MARK: - UITableViewDataSource & UITableViewDelegate
extension FollowingViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredDataList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "UserTableViewCell", for: indexPath) as? UserTableViewCell
        else { return UITableViewCell() }
        
        let profile = filteredDataList[indexPath.row]
        let isFollowing = AppDependencies.shared.followRepository.followingIds.contains(profile.userId)
        
        cell.configure(profile: profile, isFollowing: isFollowing)
        
        cell.onActionTap = { [weak self] in
            guard let self = self else { return }
            
            let profile = self.filteredDataList[indexPath.row]
            let isFollowing = self.followingSet.contains(profile.userId)
            
            if self.listType == .following || isFollowing {
                self.openChat(with: profile)
            } else {
                // Update data source properly
                let id = profile.id
                let currentUserId = Auth.auth().currentUser?.uid ?? ""
                if let index = self.dataList.firstIndex(where: { $0.id == id }) {
                    if self.dataList[index].followers == nil {
                        self.dataList[index].followers = []
                    }
                    self.dataList[index].followers?.append(currentUserId)
                }
                
                if self.filteredDataList[indexPath.row].followers == nil {
                    self.filteredDataList[indexPath.row].followers = []
                }
                
                self.filteredDataList[indexPath.row].followers?.append(currentUserId)
                
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedProfile = filteredDataList[indexPath.row]
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        guard let otherVC = storyboard.instantiateViewController(
            withIdentifier: "OtherUserProfileViewController"
        ) as? OtherUserProfileViewController else {
            assertionFailure("VC not found in storyboard")
            return
        }
        
        otherVC.profile = selectedProfile
        navigationController?.pushViewController(otherVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let profile = filteredDataList[indexPath.row]
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            
            let message = UIAction(title: "Message", image: UIImage(systemName: "message")) { _ in
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                if let vc = storyboard.instantiateViewController(withIdentifier: "ChatViewController") as? ChatViewController {
                    guard let currentUserId = Auth.auth().currentUser?.uid else { return }
                    let conversationId = [currentUserId, profile.userId].sorted().joined(separator: "_")
                    vc.conversation = self?.makeConversation(from: profile, id: conversationId)
                    vc.hidesBottomBarWhenPushed = true
                    self?.navigationController?.pushViewController(vc, animated: true)
                }
            }
            
            let mute = UIAction(title: "Mute", image: UIImage(systemName: "speaker.slash")) { _ in }
            
            let remove = UIAction(title: "Unfollow", image: UIImage(systemName: "person.badge.minus")) { _ in
                let alert = UIAlertController(
                    title: "Unfollow User",
                    message: "Are you sure you want to unfollow \(profile.fullName)?",
                    preferredStyle: .alert
                )
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                
                alert.addAction(UIAlertAction(title: "Unfollow", style: .destructive) { _ in
                    let id = profile.id
                    let currentUserId = Auth.auth().currentUser?.uid ?? ""
                    let _ = AppDependencies.shared.followRepository.toggleFollow(currentUserId: currentUserId, targetUserId: profile.userId)
                    
                    self?.filteredDataList.remove(at: indexPath.row)
                    self?.dataList.removeAll { $0.id == id }
                    tableView.deleteRows(at: [indexPath], with: .automatic)
                })
                
                self?.present(alert, animated: true)
            }
            
            let block = UIAction(title: "Block", image: UIImage(systemName: "hand.raised.slash"), attributes: .destructive) { _ in }
            
            return UIMenu(title: "", children: [message, mute, remove, block])
        }
    }
}
