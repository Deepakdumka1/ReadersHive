//
//  MessageViewController.swift
//  FinalMessageNavigator
//
//  Created by GEU on 14/02/26.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class MessageViewController: UIViewController {
    
    var dataModel : MessageDataModel!
    var allConversations: [Conversation] = []
    var conversationList : [Conversation] = []
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var newMessageButton: UIBarButtonItem!
    @IBOutlet weak var filterButton: UIBarButtonItem!
    
    @IBOutlet weak var messageTableView: UITableView!
    
    
    @IBAction func newMessageButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: "newMessage", sender: nil)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        assert(dataModel != nil, "dataModel was not injected from SceneDelegate")
        
        setupFilterMenu()
        setupSearchBar()
        registerCells()
        setupUI()
        
        NotificationCenter.default.addObserver(self, selector: #selector(dataUpdated), name: NSNotification.Name("conversationsUpdated"), object: nil)
        dataUpdated()
    }
    
    @objc func dataUpdated() {
        allConversations = dataModel.getConversations()
        if searchBar.text?.isEmpty ?? true {
            conversationList = allConversations
        }
        DispatchQueue.main.async {
            self.messageTableView.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dataModel.listenForConversations { [weak self] in
            self?.dataUpdated()
        }
    }
    
    private func setupUI() {
        NSLayoutConstraint.activate([
            messageTableView.topAnchor.constraint(equalTo: view.topAnchor),
            messageTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            messageTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            messageTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupFilterMenu() {
        
        let markReadAction = UIAction(title: "Mark all as Read",
                                      image: UIImage(systemName: "checkmark.circle")) { _ in }
        
        let mutedAction = UIAction(title: "Muted",
                                   image: UIImage(systemName: "bell.slash")) { _ in }
        
        let deletedAction = UIAction(title: "Recently Deleted",
                                     image: UIImage(systemName: "trash")) { _ in }
        
        let sortMenu = UIMenu(title: "Sort by",
                              image: UIImage(systemName: "slider.horizontal.3"),
                              children: [
                                UIAction(title: "Newest First") { _ in },
                                UIAction(title: "Oldest First") { _ in },
                                UIAction(title: "Unread First") { _ in }
                              ])
        
        let filterMenu = UIMenu(title: "Filter",
                                children: [
                                    markReadAction,
                                    mutedAction,
                                    deletedAction,
                                    sortMenu
                                ])
        
        filterButton.menu = filterMenu
    }
    
    
    private func setupSearchBar() {
        searchBar.placeholder = "Search Users"
        searchBar.searchBarStyle = .minimal
        searchBar.sizeToFit()
        searchBar.keyboardAppearance = .default
        searchBar.keyboardType = .default
        searchBar.delegate = self
    }
    
    
    private func registerCells() {
        let nib = UINib(nibName: "MessageTableViewCell", bundle: nil)
        messageTableView.register(nib, forCellReuseIdentifier: "messageCell")
        
        messageTableView.rowHeight = UITableView.automaticDimension
        messageTableView.estimatedRowHeight = 80
        
        messageTableView.keyboardDismissMode = .onDrag
        
        messageTableView.delegate = self
        messageTableView.dataSource = self
    }
}




//MARK: - UISearchBarDelegate
extension MessageViewController : UISearchBarDelegate {
    
    //fires every keystroke
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let queryText = searchText.lowercased()
        if queryText.isEmpty {
            conversationList = allConversations
            messageTableView.reloadData()
            return
        }

        // 1. Local filter for existing conversations
        let existing = allConversations.filter { $0.otherUserName.lowercased().contains(queryText) }
        self.conversationList = existing
        self.messageTableView.reloadData()

        // 2. Remote search for followed users NOT in current chats
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        // Fetch matching profiles
        db.collection("profiles")
            .whereField("fullName", isGreaterThanOrEqualTo: searchText)
            .whereField("fullName", isLessThanOrEqualTo: searchText + "\u{f8ff}")
            .limit(to: 5)
            .getDocuments { [weak self] snapshot, _ in
                guard let self = self else { return }
                let profiles = snapshot?.documents.compactMap { try? $0.data(as: Profile.self) } ?? []
                
                // Only show people we actually follow
                db.collection("profiles").document(currentUserId).getDocument { [weak self] profileSnap, _ in
                    guard let self = self else { return }
                    let followingIds = profileSnap?.data()?["following"] as? [String] ?? []
                    
                    let newDummies = profiles.compactMap { profile -> Conversation? in
                        guard followingIds.contains(profile.userId) else { return nil }
                        guard !self.allConversations.contains(where: { $0.otherUserId == profile.userId }) else { return nil }
                        
                        return Conversation(
                            id: "new_\(profile.userId)",
                            otherUserId: profile.userId,
                            otherUserName: profile.fullName,
                            avatarImage: profile.avatarUrl ?? "",
                            lastMessage: "Start a new chat",
                            lastMessageTimestamp: nil
                        )
                    }
                    
                    DispatchQueue.main.async {
                        // Append results if they aren't already there
                        for dummy in newDummies {
                            if !self.conversationList.contains(where: { $0.otherUserId == dummy.otherUserId }) {
                                self.conversationList.append(dummy)
                            }
                        }
                        self.messageTableView.reloadData()
                    }
                }
            }
    }
    
    //fires when search button tapped
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}




//MARK: - UITableViewDelegate and DataSource
extension MessageViewController : UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //print(conversationList.count)
        return conversationList.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "messageCell", for: indexPath) as? MessageTableViewCell
        else {
            print("error loading tableview")
            return UITableViewCell()
        }
        
        let chat = conversationList[indexPath.row]
        
        cell.configure(with: chat)
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selected = conversationList[indexPath.row]
        
        if selected.id.hasPrefix("new_") {
            // Start a brand new conversation
            guard let currentUserId = Auth.auth().currentUser?.uid else { return }
            let otherUserId = selected.otherUserId
            let conversationId = [currentUserId, otherUserId].sorted().joined(separator: "_")
            
            // Create the real conversation object
            let realConv = Conversation(
                id: conversationId,
                otherUserId: otherUserId,
                otherUserName: selected.otherUserName,
                avatarImage: selected.avatarImage,
                lastMessage: "",
                lastMessageTimestamp: Date()
            )
            
            navigateToChat(with: realConv)
        } else {
            // Existing conversation
            navigateToChat(with: selected)
        }
    }
    
    private func navigateToChat(with conversation: Conversation) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let chatVC = storyboard.instantiateViewController(withIdentifier: "ChatViewController") as? ChatViewController else { return }
        
        chatVC.hidesBottomBarWhenPushed = true
        chatVC.conversation = conversation
        
        navigationController?.pushViewController(chatVC, animated: true)
    }
}

