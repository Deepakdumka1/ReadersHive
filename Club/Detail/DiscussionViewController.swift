//
//  DiscussionViewController.swift
//  Club
//
//  Created by Manas  on 02/04/26.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

// MARK: - Delegate to pass new discussion back (same pattern as other delegates in project)
protocol NewDiscussionDelegate: AnyObject {
    func didCreateDiscussion(_ post: DiscussionPost)
}

class DiscussionViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var titleTextView: UITextView!
    @IBOutlet weak var DescriptionTextView: UITextView!
    
    // MARK: - Properties
    weak var delegate: NewDiscussionDelegate?
    private var selectedBook: Book?
    private let bookshelfData = BookshelfData()
    private var currentUserProfile: Profile?
    
    private var categoryButtons: [UIButton] = []
    private let categories = ["Theme", "Setting", "Spoiler", "Author"]
    private var selectedCategory: String?
    
    // MARK: - Custom UI Elements
    private let customTitleField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Discussion Title"
        tf.font = .systemFont(ofSize: 18, weight: .semibold)
        tf.textColor = .label
        tf.backgroundColor = .systemBackground
        tf.layer.cornerRadius = 14
        tf.layer.borderWidth = 1
        tf.layer.borderColor = UIColor.systemGray5.cgColor
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 1))
        tf.leftViewMode = .always
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let customDescriptionView: UITextView = {
        let tv = UITextView()
        tv.font = .systemFont(ofSize: 16, weight: .regular)
        tv.textColor = .label
        tv.backgroundColor = .systemBackground
        tv.layer.cornerRadius = 14
        tv.layer.borderWidth = 1
        tv.layer.borderColor = UIColor.systemGray5.cgColor
        tv.textContainerInset = UIEdgeInsets(top: 16, left: 12, bottom: 16, right: 12)
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    private let descriptionPlaceholderLabel: UILabel = {
        let label = UILabel()
        label.text = "What would you like to discuss?"
        label.font = .systemFont(ofSize: 16)
        label.textColor = .placeholderText
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let tagBookButton: UIButton = {
        let button = UIButton(type: .system)
        
        var config = UIButton.Configuration.filled()
        config.title = "🏷️ Tag a Book"
        config.cornerStyle = .capsule
        config.baseBackgroundColor = UIColor(red: 0.47, green: 0.34, blue: 0.85, alpha: 1.0)
        config.baseForegroundColor = .white
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 24, bottom: 12, trailing: 24)
        
        if #available(iOS 15.0, *) {
            var container = AttributeContainer()
            container.font = UIFont.systemFont(ofSize: 16, weight: .bold)
            config.attributedTitle = AttributedString("🏷️ Tag a Book", attributes: container)
        }
        
        button.configuration = config
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let taggedBookLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .bold)
        label.textColor = .systemIndigo
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "No book tagged"
        return label
    }()
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupPremiumUI()
        fetchUserProfile()
    }
    
    private func fetchUserProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore().collection("profiles").document(uid).getDocument { [weak self] snapshot, _ in
            if let profile = try? snapshot?.data(as: Profile.self) {
                self?.currentUserProfile = profile
            }
        }
    }
    
    private func setupPremiumUI() {
        // Hide the storyboard's basic text views
        titleTextView.isHidden = true
        DescriptionTextView.isHidden = true
        
        // Setup background
        view.backgroundColor = .systemBackground
        
        let categoryStack = UIStackView()
        categoryStack.axis = .horizontal
        categoryStack.distribution = .fillEqually
        categoryStack.spacing = 10
        categoryStack.translatesAutoresizingMaskIntoConstraints = false
        
        for cat in categories {
            let btn = UIButton(type: .system)
            btn.setTitle(cat, for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
            btn.backgroundColor = .secondarySystemBackground
            btn.setTitleColor(.label, for: .normal)
            btn.layer.cornerRadius = 18
            btn.addTarget(self, action: #selector(categoryButtonTapped(_:)), for: .touchUpInside)
            categoryButtons.append(btn)
            categoryStack.addArrangedSubview(btn)
        }
        
        // Add programmatic subviews
        view.addSubview(customTitleField)
        view.addSubview(customDescriptionView)
        customDescriptionView.addSubview(descriptionPlaceholderLabel)
        customDescriptionView.delegate = self
        
        view.addSubview(categoryStack)
        view.addSubview(tagBookButton)
        view.addSubview(taggedBookLabel)
        
        // Layout using Safe Area Anchors (Prevents frame cuts)
        let safeArea = view.safeAreaLayoutGuide
        
        NSLayoutConstraint.activate([
            customTitleField.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 24),
            customTitleField.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 20),
            customTitleField.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -20),
            customTitleField.heightAnchor.constraint(equalToConstant: 56),
            
            customDescriptionView.topAnchor.constraint(equalTo: customTitleField.bottomAnchor, constant: 16),
            customDescriptionView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 20),
            customDescriptionView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -20),
            customDescriptionView.heightAnchor.constraint(equalToConstant: 240),
            
            descriptionPlaceholderLabel.topAnchor.constraint(equalTo: customDescriptionView.topAnchor, constant: 16),
            descriptionPlaceholderLabel.leadingAnchor.constraint(equalTo: customDescriptionView.leadingAnchor, constant: 16),
            descriptionPlaceholderLabel.trailingAnchor.constraint(equalTo: customDescriptionView.trailingAnchor, constant: -16),
            
            categoryStack.topAnchor.constraint(equalTo: customDescriptionView.bottomAnchor, constant: 16),
            categoryStack.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 20),
            categoryStack.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -20),
            categoryStack.heightAnchor.constraint(equalToConstant: 36),
            
            tagBookButton.topAnchor.constraint(equalTo: categoryStack.bottomAnchor, constant: 24),
            tagBookButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            tagBookButton.heightAnchor.constraint(equalToConstant: 48),
            
            taggedBookLabel.topAnchor.constraint(equalTo: tagBookButton.bottomAnchor, constant: 12),
            taggedBookLabel.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 20),
            taggedBookLabel.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -20)
        ])
        
        tagBookButton.addTarget(self, action: #selector(tagBookTapped), for: .touchUpInside)
        
        // Dismiss keyboard on tap
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func categoryButtonTapped(_ sender: UIButton) {
        for btn in categoryButtons {
            if btn == sender {
                btn.backgroundColor = UIColor(red: 0.47, green: 0.34, blue: 0.85, alpha: 1.0)
                btn.setTitleColor(.white, for: .normal)
                selectedCategory = btn.title(for: .normal)
            } else {
                btn.backgroundColor = .secondarySystemBackground
                btn.setTitleColor(.label, for: .normal)
            }
        }
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func tagBookTapped() {
        let pickerVC = BookTagPickerViewController()
        pickerVC.books = bookshelfData.allBooks
        pickerVC.onBookSelected = { [weak self] book in
            self?.selectedBook = book
            self?.taggedBookLabel.text = "🏷️ Tagged: \(book.title)"
        }
        present(pickerVC, animated: true)
    }
    

    // MARK: - Actions
    
    @IBAction func DoneButton(_ sender: Any) {
        let title = customTitleField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let description = customDescriptionView.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        guard !title.isEmpty else {
            showAlert(message: "Please enter a title.")
            return
        }
        guard !description.isEmpty else {
            showAlert(message: "Please enter a description.")
            return
        }
        
        let finalTitle = selectedBook != nil ? "\(title) [Book: \(selectedBook!.title)]" : title
        
        let realUid = Auth.auth().currentUser?.uid ?? currentUserId
        
        let newPost = DiscussionPost(
            id: UUID().uuidString,
            userId: realUid,
            title: finalTitle,
            content: description,
            authorName: currentUserProfile?.fullName ?? realUid,
            postType: selectedCategory ?? "Theme",
            createdAt: "Just now",
            upvotes: 0,
            commentCount: 0
        )
        
        delegate?.didCreateDiscussion(newPost)
        dismiss(animated: true)
    }
    
    @IBAction func CrossButton(_ sender: Any) {
        dismiss(animated: true)
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Missing Info", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension DiscussionViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        descriptionPlaceholderLabel.isHidden = !textView.text.isEmpty
    }
}
