import UIKit
import FirebaseFirestore
import FirebaseAuth

class DiscussionDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var commentTextField: UITextField!
    @IBOutlet weak var inputBottomConstraint: NSLayoutConstraint!
    
    var post: DiscussionPost!
    var clubId: String!
    
    var comments: [Comment] = []
    private var postListener: ListenerRegistration?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 150
        tableView.backgroundColor = .systemGroupedBackground
        
        commentTextField.delegate = self
        
        // Keyboard handling
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        
        setupLiveListener()
    }
    
    deinit {
        postListener?.remove()
    }
    
    private func setupLiveListener() {
        guard let clubId = clubId else { return }
        let db = Firestore.firestore()
        postListener = db.collection("clubs").document(clubId).collection("discussionPosts").document(post.id).addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            if let doc = snapshot, let updatedPost = try? doc.data(as: DiscussionPost.self) {
                self.post = updatedPost
                self.comments = updatedPost.comments ?? []
                // Ensure comments are sorted newest first or oldest first. 
                // We'll keep the order they are in the array (usually chronological).
                // Let's reverse them if we want newest at top, but usually chron is fine.
                // Assuming append adds to end, we can reverse to show newest first.
                self.comments.reverse() 
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            inputBottomConstraint.constant = keyboardSize.height - view.safeAreaInsets.bottom
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        inputBottomConstraint.constant = 0
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @IBAction func postCommentTapped(_ sender: UIButton) {
        submitComment()
    }
    
    func submitComment() {
        guard let text = commentTextField.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let clubId = clubId else { return }
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // Optimistic UI update
        let tempComment = Comment(
            id: UUID().uuidString,
            postId: post.id,
            userId: currentUserId,
            content: text,
            authorName: "You",
            createdAt: "Just now",
            upvotes: 0
        )
        comments.insert(tempComment, at: 0)
        tableView.reloadData()
        
        let textToSave = text
        commentTextField.text = ""
        dismissKeyboard()
        
        if comments.count > 0 {
            tableView.scrollToRow(at: IndexPath(row: 0, section: 1), at: .top, animated: true)
        }
        
        Task {
            do {
                let db = Firestore.firestore()
                let profileDoc = try? await db.collection("profiles").document(currentUserId).getDocument()
                let fullName = profileDoc?.data()?["fullName"] as? String ?? "User"
                
                let newComment = Comment(
                    id: UUID().uuidString,
                    postId: self.post.id,
                    userId: currentUserId,
                    content: textToSave,
                    authorName: fullName,
                    createdAt: "Just now",
                    upvotes: 0
                )
                
                var updatedPost = self.post!
                var currentComments = updatedPost.comments ?? []
                currentComments.append(newComment)
                updatedPost.comments = currentComments
                updatedPost.commentCount = currentComments.count
                
                try db.collection("clubs").document(clubId).collection("discussionPosts").document(updatedPost.id).setData(from: updatedPost)
            } catch {
                print("Failed to submit comment: \(error)")
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        submitComment()
        return true
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 1 : comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as! PostCell
            cell.configure(with: post)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell", for: indexPath) as! CommentCell
            let comment = comments[indexPath.row]
            cell.configure(with: comment)
            return cell
        }
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            let selectedComment = comments[indexPath.row]
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let vc = storyboard.instantiateViewController(withIdentifier: "DiscussionDetailViewController") as? DiscussionDetailViewController {
                
                let threadPost = DiscussionPost(
                    id: UUID().uuidString,
                    userId: selectedComment.userId,
                    title: "",
                    content: selectedComment.content,
                    authorName: selectedComment.authorName ?? selectedComment.userId,
                    postType: nil,
                    createdAt: selectedComment.createdAt ?? "",
                    upvotes: selectedComment.upvotes ?? 0,
                    commentCount: 0
                )
                
                vc.post = threadPost
                vc.comments = []
                
                navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 1 {
            let headerView = UIView()
            headerView.backgroundColor = .clear
            
            let titleLabel = UILabel()
            titleLabel.text = "All Comments"
            titleLabel.font = .boldSystemFont(ofSize: 18)
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            
            let sortButton = UIButton(type: .system)
            sortButton.setTitle("Newest ↓", for: .normal)
            sortButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
            sortButton.backgroundColor = .systemBackground
            sortButton.layer.cornerRadius = 16
            sortButton.setTitleColor(.label, for: .normal)
            sortButton.layer.borderWidth = 1
            sortButton.layer.borderColor = UIColor.systemGray5.cgColor
            sortButton.translatesAutoresizingMaskIntoConstraints = false
            
            headerView.addSubview(titleLabel)
            headerView.addSubview(sortButton)
            
            NSLayoutConstraint.activate([
                titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
                titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
                
                sortButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
                sortButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
                sortButton.heightAnchor.constraint(equalToConstant: 32),
                sortButton.widthAnchor.constraint(equalToConstant: 90)
            ])
            
            return headerView
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 1 ? 50 : 0
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
}
