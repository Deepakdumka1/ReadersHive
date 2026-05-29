import UIKit
import FirebaseFirestore

class CommentsViewController: UIViewController {

    var post: FeedPost?
    var feedData: FeedData?
    var showPostHeader: Bool = false
    
    private var comments: [PostComment] = []
    private var listener: ListenerRegistration?
    
    private let tableView = UITableView()
    private let inputTextField = UITextField()
    private let sendButton = UIButton(type: .system)
    private let bottomContainer = UIView()
    private var bottomConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        setupUI()
        setupKeyboardObservers()
        
        if let postId = post?.id, let feedData = feedData {
            listener = feedData.fetchComments(for: postId) { [weak self] fetchedComments in
                self?.comments = fetchedComments
                self?.tableView.reloadData()
                if !fetchedComments.isEmpty {
                    self?.tableView.scrollToRow(at: IndexPath(row: fetchedComments.count - 1, section: 0), at: .bottom, animated: true)
                }
            }
        }
    }
    
    deinit {
        listener?.remove()
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupUI() {
        self.title = "Comments"
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(PostCommentCell.self, forCellReuseIdentifier: PostCommentCell.identifier)
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        
        if let post = post, showPostHeader {
            let headerView = PostHeaderView(frame: .zero)
            headerView.configure(with: post)
            
            // Calculate dynamic height for header
            let targetSize = CGSize(width: view.bounds.width, height: UIView.layoutFittingCompressedSize.height)
            let size = headerView.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
            
            headerView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: size.height)
            tableView.tableHeaderView = headerView
        }
        
        view.addSubview(tableView)
        
        bottomContainer.translatesAutoresizingMaskIntoConstraints = false
        bottomContainer.backgroundColor = .systemGray6
        view.addSubview(bottomContainer)
        
        inputTextField.translatesAutoresizingMaskIntoConstraints = false
        inputTextField.placeholder = "Write a comment..."
        inputTextField.borderStyle = .roundedRect
        bottomContainer.addSubview(inputTextField)
        
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.setTitle("Send", for: .normal)
        sendButton.addTarget(self, action: #selector(sendComment), for: .touchUpInside)
        bottomContainer.addSubview(sendButton)
        
        bottomConstraint = bottomContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomContainer.topAnchor),
            
            bottomContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomConstraint,
            bottomContainer.heightAnchor.constraint(equalToConstant: 60),
            
            inputTextField.leadingAnchor.constraint(equalTo: bottomContainer.leadingAnchor, constant: 16),
            inputTextField.centerYAnchor.constraint(equalTo: bottomContainer.centerYAnchor),
            inputTextField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -12),
            inputTextField.heightAnchor.constraint(equalToConstant: 40),
            
            sendButton.trailingAnchor.constraint(equalTo: bottomContainer.trailingAnchor, constant: -16),
            sendButton.centerYAnchor.constraint(equalTo: bottomContainer.centerYAnchor)
        ])
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            let safeAreaBottom = view.safeAreaInsets.bottom
            bottomConstraint.constant = -(keyboardFrame.height - safeAreaBottom)
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }
        }
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        bottomConstraint.constant = 0
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }

    @objc private func sendComment() {
        guard let text = inputTextField.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, let postId = post?.id else { return }
        feedData?.addComment(to: postId, content: text)
        inputTextField.text = ""
        inputTextField.resignFirstResponder()
    }
}

extension CommentsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PostCommentCell.identifier, for: indexPath) as? PostCommentCell else {
            return UITableViewCell()
        }
        
        let comment = comments[indexPath.row]
        cell.configure(with: comment)
        return cell
    }
}
