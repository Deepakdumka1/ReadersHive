//
//  ChatRoomViewController.swift
//  Club
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class ChatRoomViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextField: UITextField!

    // Set by KafkaViewController before push
    var chatRoom: ChatRoom!
    var clubId: String!
    var messages: [ChatRoomMessage] = []
    
    private var listener: ListenerRegistration?
    private var currentUserProfile: Profile?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "# \(chatRoom.title)"

        // Load messages from the chatRoom model
        messages = chatRoom.messages ?? []

        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
        tableView.separatorStyle = .none
        
        fetchCurrentUserProfile()
        listenForMessages()
    }
    
    deinit {
        listener?.remove()
    }
    
    private func fetchCurrentUserProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore().collection("profiles").document(uid).getDocument { [weak self] snapshot, _ in
            if let profile = try? snapshot?.data(as: Profile.self) {
                self?.currentUserProfile = profile
            }
        }
    }
    
    private func listenForMessages() {
        listener?.remove()
        listener = Firestore.firestore().collection("clubs").document(clubId).collection("chatrooms").document(chatRoom.id).addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            if let updatedRoom = try? snapshot?.data(as: ChatRoom.self) {
                self.chatRoom = updatedRoom
                self.messages = updatedRoom.messages ?? []
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.scrollToBottom()
                }
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scrollToBottom()
    }

    // MARK: - Send Button

    @IBAction func sendButtonTapped(_ sender: UIButton) {
        guard let text = messageTextField.text, !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let currentUid = Auth.auth().currentUser?.uid ?? currentUserId
        
        let newMessage = ChatRoomMessage(
            userId: currentUid,
            name: currentUserProfile?.fullName ?? "User",
            text: text,
            time: currentTimeString(),
            isMine: false, // isMine is calculated on display
            avatarUrl: currentUserProfile?.avatarUrl
        )
        
        // Optimistic UI update
        messages.append(newMessage)
        messageTextField.text = ""
        tableView.reloadData()
        scrollToBottom()
        
        // Save to Firebase
        // Append to the chatroom's messages array
        chatRoom.messages = messages
        do {
            try Firestore.firestore().collection("clubs").document(clubId).collection("chatrooms").document(chatRoom.id).setData(from: chatRoom)
        } catch {
            print("Failed to save message: \(error)")
        }
    }

    // MARK: - TableView DataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as! ChatRoomMessageCell
        var message = messages[indexPath.row]
        let currentUid = Auth.auth().currentUser?.uid ?? currentUserId
        message.isMine = (message.userId == currentUid)
        cell.configure(with: message)
        return cell
    }

    // MARK: - Helpers

    func scrollToBottom() {
        guard messages.count > 0 else { return }
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }

    func currentTimeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: Date())
    }
}
