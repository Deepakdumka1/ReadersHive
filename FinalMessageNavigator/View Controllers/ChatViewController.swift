import UIKit
import FirebaseFirestore
import FirebaseAuth

// MARK: - MessageCell
class MessageCell: UITableViewCell {
    
    private let bubbleView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 18
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let messageLabel: UILabel = {
        let l = UILabel()
        l.numberOfLines = 0
        l.font = .systemFont(ofSize: 16, weight: .regular)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let timeLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 10, weight: .light)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private var leadingConstraint: NSLayoutConstraint!
    private var trailingConstraint: NSLayoutConstraint!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(bubbleView)
        bubbleView.addSubview(messageLabel)
        contentView.addSubview(timeLabel)
        
        leadingConstraint = bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
        trailingConstraint = bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        
        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            bubbleView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.75),
            
            messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 10),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -10),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 14),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -14),
            
            timeLabel.topAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 2),
            timeLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 4),
            timeLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -4)
        ])
    }
    
    func configure(text: String, time: String, isOutgoing: Bool) {
        messageLabel.text = text
        timeLabel.text = time
        timeLabel.textAlignment = isOutgoing ? .right : .left
        
        if isOutgoing {
            leadingConstraint.isActive = false
            trailingConstraint.isActive = true
            bubbleView.backgroundColor = UIColor(red: 0.45, green: 0.35, blue: 0.95, alpha: 1.0)
            messageLabel.textColor = .white
            bubbleView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner]
        } else {
            trailingConstraint.isActive = false
            leadingConstraint.isActive = true
            bubbleView.backgroundColor = .systemGray6
            messageLabel.textColor = .label
            bubbleView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        }
    }
}

// MARK: - ChatViewController
class ChatViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var inputBarBottomConstraint: NSLayoutConstraint!
    
    private let sendButton: UIButton = {
        let b = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        b.setImage(UIImage(systemName: "arrow.up.circle.fill", withConfiguration: config), for: .normal)
        b.tintColor = UIColor(red: 0.45, green: 0.35, blue: 0.95, alpha: 1.0)
        return b
    }()
    
    var conversation: Conversation!
    private var messages: [Message] = []
    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        setupKeyboardObservers()
        listenForMessages()
    }
    
    private func setupUI() {
        title = conversation.otherUserName
        navigationController?.navigationBar.prefersLargeTitles = false
        
        view.backgroundColor = .systemBackground
        
        // Customizing input bar
        guard let inputBar = messageTextField.superview else { return }
        inputBar.backgroundColor = .systemBackground
        
        messageTextField.layer.cornerRadius = 20
        messageTextField.backgroundColor = .systemGray6
        messageTextField.borderStyle = .none
        messageTextField.placeholder = "Message..."
        
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: 40))
        messageTextField.leftView = paddingView
        messageTextField.leftViewMode = .always
        
        messageTextField.rightView = sendButton
        messageTextField.rightViewMode = .always
        sendButton.frame = CGRect(x: 0, y: 0, width: 44, height: 40)
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
    }
    
    private func setupTableView() {
        tableView.register(MessageCell.self, forCellReuseIdentifier: "MessageCell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.keyboardDismissMode = .interactive
    }
    
    private func listenForMessages() {
        listener?.remove()
        listener = db.collection("conversations").document(conversation.id).collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self = self else { return }
                self.messages = snapshot?.documents.compactMap { doc -> Message? in
                    let data = doc.data()
                    return Message(
                        id: doc.documentID,
                        senderId: data["sender_id"] as? String ?? "",
                        content: data["content"] as? String ?? "",
                        timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date(),
                        isRead: data["is_read"] as? Bool ?? false
                    )
                } ?? []
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.scrollToBottom()
                }
            }
    }
    
    @objc private func sendTapped() {
        guard let text = messageTextField.text, !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let messageData: [String: Any] = [
            "sender_id": currentUserId,
            "content": text,
            "timestamp": FieldValue.serverTimestamp(),
            "is_read": false
        ]
        
        let convRef = db.collection("conversations").document(conversation.id)
        let participants = [currentUserId, conversation.otherUserId].sorted()
        
        convRef.setData([
            "participants": participants,
            "last_message": text,
            "last_message_timestamp": FieldValue.serverTimestamp(),
            "other_user_name": conversation.otherUserName,
            "avatar_image": conversation.avatarImage
        ], merge: true)
        
        convRef.collection("messages").addDocument(data: messageData)
        messageTextField.text = ""
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { [weak self] n in
            if let frame = n.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                self?.inputBarBottomConstraint.constant = frame.height - (self?.view.safeAreaInsets.bottom ?? 0)
                UIView.animate(withDuration: 0.3) { self?.view.layoutIfNeeded() }
                self?.scrollToBottom()
            }
        }
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { [weak self] _ in
            self?.inputBarBottomConstraint.constant = 0
            UIView.animate(withDuration: 0.3) { self?.view.layoutIfNeeded() }
        }
    }
    
    func scrollToBottom() {
        if messages.count > 0 {
            tableView.scrollToRow(at: IndexPath(row: messages.count - 1, section: 0), at: .bottom, animated: true)
        }
    }
}

extension ChatViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as! MessageCell
        let msg = messages[indexPath.row]
        let isOutgoing = msg.senderId == Auth.auth().currentUser?.uid
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let timeString = formatter.string(from: msg.timestamp)
        
        cell.configure(text: msg.content, time: timeString, isOutgoing: isOutgoing)
        return cell
    }
}

extension ChatViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendTapped()
        return true
    }
}
