//
//  BookReplyViewController.swift
//  Club
//
//  Created by Antigravity on 28/04/26.
//
//  High-fidelity Discussion detail screen matching the Figma mockup.
//  Shows original post card at top, threaded replies, and message box at bottom.
//  Enforces club membership for participation.
//

import UIKit
import FirebaseAuth

protocol BookReplyDelegate: AnyObject {
    func didPostReply(to discussionId: String, content: String)
}

class BookReplyViewController: UIViewController, UITextFieldDelegate {

    weak var delegate: BookReplyDelegate?
    var discussion: BookDiscussion?

    // MARK: - Custom Header

    private let customHeaderView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .systemBackground
        return v
    }()

    private let backButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 13, weight: .bold)
        b.setImage(UIImage(systemName: "chevron.left", withConfiguration: config), for: .normal)
        b.tintColor = UIColor.label
        b.backgroundColor = .white
        b.layer.cornerRadius = 20
        b.layer.shadowColor = UIColor.black.cgColor
        b.layer.shadowOpacity = 0.08
        b.layer.shadowRadius = 4
        b.layer.shadowOffset = CGSize(width: 0, height: 2)
        b.layer.masksToBounds = false
        return b
    }()

    private let headerTitleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "Discussion"
        l.font = .systemFont(ofSize: 17, weight: .semibold)
        l.textColor = .label
        l.textAlignment = .center
        return l
    }()

    private let headerSeparator: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor(red: 0.92, green: 0.92, blue: 0.94, alpha: 1.0)
        return v
    }()

    // MARK: - Scroll Content

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.alwaysBounceVertical = true
        sv.keyboardDismissMode = .interactive
        return sv
    }()

    private let contentStack: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .vertical
        sv.spacing = 16
        return sv
    }()

    // MARK: - Original Post Card

    private let originalPostCard: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .white
        v.layer.cornerRadius = 16
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.05
        v.layer.shadowRadius = 8
        v.layer.shadowOffset = CGSize(width: 0, height: 4)
        v.layer.masksToBounds = false
        return v
    }()

    private let avatarLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 18)
        l.textAlignment = .center
        l.backgroundColor = UIColor(red: 0.95, green: 0.93, blue: 0.98, alpha: 1.0)
        l.layer.cornerRadius = 20
        l.layer.masksToBounds = true
        return l
    }()

    private let authorNameLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 14, weight: .semibold)
        l.textColor = .label
        return l
    }()

    private let postTimestampLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 12)
        l.textColor = .secondaryLabel
        return l
    }()

    private let tagBadge: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.cornerRadius = 10
        v.layer.masksToBounds = true
        return v
    }()

    private let tagLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 10, weight: .semibold)
        return l
    }()

    private let postContentLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 16, weight: .medium)
        l.textColor = .label
        l.numberOfLines = 0
        return l
    }()

    // Like Pill
    private let likePill: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.98, alpha: 1.0)
        v.layer.cornerRadius = 15
        return v
    }()

    private let likeIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "heart")
        iv.tintColor = .secondaryLabel
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let likeCountLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 12, weight: .medium)
        l.textColor = .secondaryLabel
        l.text = "0"
        return l
    }()

    // Comment Pill
    private let commentPill: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.98, alpha: 1.0)
        v.layer.cornerRadius = 15
        return v
    }()

    private let commentIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "bubble.left")
        iv.tintColor = .secondaryLabel
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let commentCountLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 12, weight: .medium)
        l.textColor = .secondaryLabel
        l.text = "0"
        return l
    }()

    // MARK: - Comments Header

    private let commentsHeaderRow: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let allCommentsLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "All Comments"
        l.font = .systemFont(ofSize: 17, weight: .bold)
        l.textColor = .label
        return l
    }()

    private let filterChip: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .white
        v.layer.cornerRadius = 14
        v.layer.borderWidth = 1.0
        v.layer.borderColor = UIColor(red: 0.88, green: 0.88, blue: 0.91, alpha: 1.0).cgColor
        return v
    }()

    private let filterLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "Newest ↓"
        l.font = .systemFont(ofSize: 12, weight: .medium)
        l.textColor = UIColor(red: 0.35, green: 0.35, blue: 0.45, alpha: 1.0)
        return l
    }()

    private let repliesStack: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .vertical
        sv.spacing = 10
        return sv
    }()

    // MARK: - Input Bar

    private let inputContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .systemBackground
        return v
    }()

    private let inputField: UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.placeholder = "Add a comment..."
        tf.font = .systemFont(ofSize: 15)
        tf.borderStyle = .none
        tf.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.98, alpha: 1.0)
        tf.layer.cornerRadius = 20
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 1))
        tf.leftViewMode = .always
        tf.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 1))
        tf.rightViewMode = .always
        return tf
    }()

    private let sendButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setTitle("Post", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        b.tintColor = UIColor(red: 0.0, green: 0.46, blue: 1.0, alpha: 1.0)
        return b
    }()

    /// Banner shown above input field when user is not a club member
    private let joinBanner: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor(red: 1.0, green: 0.96, blue: 0.88, alpha: 1.0)
        v.layer.cornerRadius = 10
        return v
    }()

    private let joinBannerLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "🔒 Join this club to comment and participate"
        l.font = .systemFont(ofSize: 13, weight: .medium)
        l.textColor = UIColor(red: 0.6, green: 0.4, blue: 0.0, alpha: 1.0)
        l.textAlignment = .center
        return l
    }()

    private var inputBottomConstraint: NSLayoutConstraint!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.97, green: 0.97, blue: 0.99, alpha: 1.0)
        navigationController?.setNavigationBarHidden(true, animated: false)

        setupLayout()
        populatePost()

        // Lock/unlock input bar immediately based on membership
        updateInputBarState(isMember: checkClubMembership())

        backButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        inputField.delegate = self

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        scrollView.addGestureRecognizer(tapGesture)
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    // MARK: - Club Membership

    private func checkClubMembership() -> Bool {
        guard let clubName = discussion?.tagLabel else { return true }
        // Use Firebase UID if available, fall back to simulated currentUserId (matches JSON data)
        let userId = Auth.auth().currentUser?.uid ?? currentUserId
        let allDetails = AppDependencies.shared.clubdetailData.clubDetails
        for (_, detail) in allDetails {
            if let name = detail.club?.name, name == clubName, let club = detail.club {
                let isMember = club.members?.contains(where: { $0.userId == userId }) ?? false
                return isMember
            }
        }
        // Club not found in local store → it's a standalone mock discussion, allow participation
        return true
    }

    private func showJoinClubAlert() {
        guard let clubName = discussion?.tagLabel else { return }
        let alert = UIAlertController(
            title: "Join Club to Participate",
            message: "You need to join '\(clubName)' before you can comment. Would you like to join now?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Not Now", style: .cancel))
        alert.addAction(UIAlertAction(title: "Join Club", style: .default) { [weak self] _ in
            self?.joinClubLocally(named: clubName)
        })
        present(alert, animated: true)
    }

    private func joinClubLocally(named name: String) {
        // Use Firebase UID if available, fall back to simulated currentUserId
        let userId = Auth.auth().currentUser?.uid ?? currentUserId
        let clubDetailsStore = AppDependencies.shared.clubdetailData.clubDetails
        var joined = false
        for (clubId, detail) in clubDetailsStore {
            guard let club = detail.club, club.name == name else { continue }
            var updatedClub = club
            var members = club.members ?? []
            if !members.contains(where: { $0.userId == userId }) {
                let newMember = ClubMember(clubId: clubId, userId: userId, role: "member", joinedAt: "\(Date())", fullName: "You")
                members.append(newMember)
                updatedClub.members = members
                AppDependencies.shared.clubdetailData.clubDetails[clubId] = ClubDetail(
                    club: updatedClub,
                    members: detail.members,
                    admins: detail.admins,
                    coAdmins: detail.coAdmins,
                    chatRooms: detail.chatRooms,
                    upcomingDiscussions: detail.upcomingDiscussions,
                    posts: detail.posts,
                    filters: detail.filters
                )
                joined = true
            }
            break
        }
        // Update the input bar to show locked/unlocked state
        updateInputBarState(isMember: true)
        
        let msg = joined ? "You are now a member of '\(name)'. You can now comment!" : "You are already a member of '\(name)'."
        let successAlert = UIAlertController(title: "Joined! 🎉", message: msg, preferredStyle: .alert)
        successAlert.addAction(UIAlertAction(title: "Got It", style: .default) { [weak self] _ in
            self?.inputField.becomeFirstResponder()
        })
        present(successAlert, animated: true)
    }
    
    private func updateInputBarState(isMember: Bool) {
        UIView.animate(withDuration: 0.25) {
            if isMember {
                self.inputField.isUserInteractionEnabled = true
                self.inputField.alpha = 1.0
                self.sendButton.isEnabled = true
                self.sendButton.alpha = 1.0
                self.inputField.placeholder = "Add a comment..."
                self.joinBanner.isHidden = true
                self.joinBanner.alpha = 0.0
            } else {
                self.inputField.isUserInteractionEnabled = false
                self.inputField.alpha = 0.4
                self.sendButton.isEnabled = false
                self.sendButton.alpha = 0.3
                self.inputField.placeholder = "Join club to comment..."
                self.joinBanner.isHidden = false
                self.joinBanner.alpha = 1.0
            }
        }
    }

    @objc private func joinBannerTapped() {
        showJoinClubAlert()
    }

    // MARK: - UITextFieldDelegate

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if !checkClubMembership() {
            showJoinClubAlert()
            return false
        }
        return true
    }

    // MARK: - Layout

    private func setupLayout() {
        // Header
        view.addSubview(customHeaderView)
        customHeaderView.addSubview(backButton)
        customHeaderView.addSubview(headerTitleLabel)
        customHeaderView.addSubview(headerSeparator)

        // Scroll
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        // Post card internals
        originalPostCard.addSubview(avatarLabel)
        originalPostCard.addSubview(authorNameLabel)
        originalPostCard.addSubview(postTimestampLabel)
        tagBadge.addSubview(tagLabel)
        originalPostCard.addSubview(tagBadge)
        originalPostCard.addSubview(postContentLabel)

        // Like pill
        likePill.addSubview(likeIcon)
        likePill.addSubview(likeCountLabel)
        originalPostCard.addSubview(likePill)

        // Comment pill
        commentPill.addSubview(commentIcon)
        commentPill.addSubview(commentCountLabel)
        originalPostCard.addSubview(commentPill)

        contentStack.addArrangedSubview(originalPostCard)

        // Comments header row
        commentsHeaderRow.addSubview(allCommentsLabel)
        filterChip.addSubview(filterLabel)
        commentsHeaderRow.addSubview(filterChip)
        contentStack.addArrangedSubview(commentsHeaderRow)

        contentStack.addArrangedSubview(repliesStack)

        // Input bar
        view.addSubview(inputContainer)
        let sep = UIView()
        sep.translatesAutoresizingMaskIntoConstraints = false
        sep.backgroundColor = UIColor(red: 0.91, green: 0.91, blue: 0.93, alpha: 1.0)
        inputContainer.addSubview(sep)
        inputContainer.addSubview(joinBanner)
        joinBanner.addSubview(joinBannerLabel)
        inputContainer.addSubview(inputField)
        inputContainer.addSubview(sendButton)

        // Join banner tap → show join alert
        let bannerTap = UITapGestureRecognizer(target: self, action: #selector(joinBannerTapped))
        joinBanner.addGestureRecognizer(bannerTap)
        joinBanner.isUserInteractionEnabled = true

        inputBottomConstraint = inputContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)

        NSLayoutConstraint.activate([
            // Header
            customHeaderView.topAnchor.constraint(equalTo: view.topAnchor),
            customHeaderView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customHeaderView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            customHeaderView.heightAnchor.constraint(equalToConstant: 100),

            backButton.bottomAnchor.constraint(equalTo: headerSeparator.topAnchor, constant: -12),
            backButton.leadingAnchor.constraint(equalTo: customHeaderView.leadingAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40),

            headerTitleLabel.centerXAnchor.constraint(equalTo: customHeaderView.centerXAnchor),
            headerTitleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),

            headerSeparator.bottomAnchor.constraint(equalTo: customHeaderView.bottomAnchor),
            headerSeparator.leadingAnchor.constraint(equalTo: customHeaderView.leadingAnchor),
            headerSeparator.trailingAnchor.constraint(equalTo: customHeaderView.trailingAnchor),
            headerSeparator.heightAnchor.constraint(equalToConstant: 0.5),

            // Scroll
            scrollView.topAnchor.constraint(equalTo: customHeaderView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: inputContainer.topAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),

            // Post Card Avatar
            avatarLabel.topAnchor.constraint(equalTo: originalPostCard.topAnchor, constant: 16),
            avatarLabel.leadingAnchor.constraint(equalTo: originalPostCard.leadingAnchor, constant: 16),
            avatarLabel.widthAnchor.constraint(equalToConstant: 40),
            avatarLabel.heightAnchor.constraint(equalToConstant: 40),

            // Author / timestamp
            authorNameLabel.topAnchor.constraint(equalTo: avatarLabel.topAnchor, constant: 3),
            authorNameLabel.leadingAnchor.constraint(equalTo: avatarLabel.trailingAnchor, constant: 10),

            postTimestampLabel.topAnchor.constraint(equalTo: authorNameLabel.bottomAnchor, constant: 2),
            postTimestampLabel.leadingAnchor.constraint(equalTo: authorNameLabel.leadingAnchor),

            // Tag badge
            tagBadge.centerYAnchor.constraint(equalTo: authorNameLabel.centerYAnchor),
            tagBadge.leadingAnchor.constraint(equalTo: authorNameLabel.trailingAnchor, constant: 6),
            tagBadge.trailingAnchor.constraint(lessThanOrEqualTo: originalPostCard.trailingAnchor, constant: -16),

            tagLabel.topAnchor.constraint(equalTo: tagBadge.topAnchor, constant: 3),
            tagLabel.bottomAnchor.constraint(equalTo: tagBadge.bottomAnchor, constant: -3),
            tagLabel.leadingAnchor.constraint(equalTo: tagBadge.leadingAnchor, constant: 8),
            tagLabel.trailingAnchor.constraint(equalTo: tagBadge.trailingAnchor, constant: -8),

            // Post content
            postContentLabel.topAnchor.constraint(equalTo: avatarLabel.bottomAnchor, constant: 14),
            postContentLabel.leadingAnchor.constraint(equalTo: originalPostCard.leadingAnchor, constant: 16),
            postContentLabel.trailingAnchor.constraint(equalTo: originalPostCard.trailingAnchor, constant: -16),

            // Like Pill
            likePill.topAnchor.constraint(equalTo: postContentLabel.bottomAnchor, constant: 14),
            likePill.leadingAnchor.constraint(equalTo: originalPostCard.leadingAnchor, constant: 16),
            likePill.heightAnchor.constraint(equalToConstant: 30),
            likePill.bottomAnchor.constraint(equalTo: originalPostCard.bottomAnchor, constant: -16),

            likeIcon.leadingAnchor.constraint(equalTo: likePill.leadingAnchor, constant: 10),
            likeIcon.centerYAnchor.constraint(equalTo: likePill.centerYAnchor),
            likeIcon.widthAnchor.constraint(equalToConstant: 15),
            likeIcon.heightAnchor.constraint(equalToConstant: 15),

            likeCountLabel.leadingAnchor.constraint(equalTo: likeIcon.trailingAnchor, constant: 5),
            likeCountLabel.centerYAnchor.constraint(equalTo: likePill.centerYAnchor),
            likeCountLabel.trailingAnchor.constraint(equalTo: likePill.trailingAnchor, constant: -12),

            // Comment Pill
            commentPill.topAnchor.constraint(equalTo: likePill.topAnchor),
            commentPill.leadingAnchor.constraint(equalTo: likePill.trailingAnchor, constant: 8),
            commentPill.heightAnchor.constraint(equalToConstant: 30),
            commentPill.bottomAnchor.constraint(equalTo: likePill.bottomAnchor),

            commentIcon.leadingAnchor.constraint(equalTo: commentPill.leadingAnchor, constant: 10),
            commentIcon.centerYAnchor.constraint(equalTo: commentPill.centerYAnchor),
            commentIcon.widthAnchor.constraint(equalToConstant: 15),
            commentIcon.heightAnchor.constraint(equalToConstant: 15),

            commentCountLabel.leadingAnchor.constraint(equalTo: commentIcon.trailingAnchor, constant: 5),
            commentCountLabel.centerYAnchor.constraint(equalTo: commentPill.centerYAnchor),
            commentCountLabel.trailingAnchor.constraint(equalTo: commentPill.trailingAnchor, constant: -12),

            // Comments header row
            commentsHeaderRow.heightAnchor.constraint(equalToConstant: 36),

            allCommentsLabel.leadingAnchor.constraint(equalTo: commentsHeaderRow.leadingAnchor),
            allCommentsLabel.centerYAnchor.constraint(equalTo: commentsHeaderRow.centerYAnchor),

            filterChip.trailingAnchor.constraint(equalTo: commentsHeaderRow.trailingAnchor),
            filterChip.centerYAnchor.constraint(equalTo: commentsHeaderRow.centerYAnchor),

            filterLabel.topAnchor.constraint(equalTo: filterChip.topAnchor, constant: 6),
            filterLabel.bottomAnchor.constraint(equalTo: filterChip.bottomAnchor, constant: -6),
            filterLabel.leadingAnchor.constraint(equalTo: filterChip.leadingAnchor, constant: 12),
            filterLabel.trailingAnchor.constraint(equalTo: filterChip.trailingAnchor, constant: -12),

            // Input bar
            inputContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputBottomConstraint,

            sep.topAnchor.constraint(equalTo: inputContainer.topAnchor),
            sep.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor),
            sep.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor),
            sep.heightAnchor.constraint(equalToConstant: 0.5),

            // Join banner (sits between separator and input field)
            joinBanner.topAnchor.constraint(equalTo: sep.bottomAnchor, constant: 8),
            joinBanner.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 16),
            joinBanner.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -16),

            joinBannerLabel.topAnchor.constraint(equalTo: joinBanner.topAnchor, constant: 8),
            joinBannerLabel.bottomAnchor.constraint(equalTo: joinBanner.bottomAnchor, constant: -8),
            joinBannerLabel.leadingAnchor.constraint(equalTo: joinBanner.leadingAnchor, constant: 12),
            joinBannerLabel.trailingAnchor.constraint(equalTo: joinBanner.trailingAnchor, constant: -12),

            inputField.topAnchor.constraint(equalTo: joinBanner.bottomAnchor, constant: 8),
            inputField.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 16),
            inputField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
            inputField.heightAnchor.constraint(equalToConstant: 40),
            inputField.bottomAnchor.constraint(equalTo: inputContainer.bottomAnchor, constant: -10),

            sendButton.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -16),
            sendButton.centerYAnchor.constraint(equalTo: inputField.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 44),
        ])
    }

    // MARK: - Populate

    private func populatePost() {
        guard let d = discussion else { return }

        avatarLabel.text = d.avatarEmoji
        authorNameLabel.text = d.username
        postTimestampLabel.text = d.timestamp
        postContentLabel.text = d.content
        commentCountLabel.text = "\(d.replies.count)"
        likeCountLabel.text = "0"

        // Tag badge color
        let tagColor = colorFromHex(d.tag.colorHex)
        tagBadge.backgroundColor = tagColor.withAlphaComponent(0.12)
        tagLabel.textColor = tagColor
        tagLabel.text = d.tagLabel

        if d.replies.isEmpty {
            // Empty state placeholder
            let emptyLabel = UILabel()
            emptyLabel.text = "No replies yet. Be the first to comment!"
            emptyLabel.font = .systemFont(ofSize: 14)
            emptyLabel.textColor = .tertiaryLabel
            emptyLabel.textAlignment = .center
            emptyLabel.translatesAutoresizingMaskIntoConstraints = false
            repliesStack.addArrangedSubview(emptyLabel)
        } else {
            for reply in d.replies {
                let card = makeReplyCard(reply)
                repliesStack.addArrangedSubview(card)
            }
        }
    }

    private func makeReplyCard(_ reply: BookDiscussionReply) -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 14
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.03
        card.layer.shadowRadius = 4
        card.layer.shadowOffset = CGSize(width: 0, height: 2)
        card.layer.masksToBounds = false
        card.translatesAutoresizingMaskIntoConstraints = false

        // Vertical thread line
        let threadLine = UIView()
        threadLine.backgroundColor = UIColor(white: 0.88, alpha: 1.0)
        threadLine.layer.cornerRadius = 1
        threadLine.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(threadLine)

        // Avatar circle
        let replyAvatar = UILabel()
        replyAvatar.text = reply.avatarEmoji
        replyAvatar.font = .systemFont(ofSize: 15)
        replyAvatar.textAlignment = .center
        replyAvatar.backgroundColor = UIColor(red: 0.95, green: 0.93, blue: 0.98, alpha: 1.0)
        replyAvatar.layer.cornerRadius = 16
        replyAvatar.layer.masksToBounds = true
        replyAvatar.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(replyAvatar)

        let nameLabel = UILabel()
        nameLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        nameLabel.textColor = .label
        nameLabel.text = reply.username
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(nameLabel)

        let timeLabel = UILabel()
        timeLabel.font = .systemFont(ofSize: 11)
        timeLabel.textColor = .secondaryLabel
        timeLabel.text = reply.timestamp
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(timeLabel)

        let bodyLabel = UILabel()
        bodyLabel.font = .systemFont(ofSize: 14)
        bodyLabel.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.25, alpha: 1.0)
        bodyLabel.text = reply.content
        bodyLabel.numberOfLines = 0
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(bodyLabel)

        // Upvote count pill
        let upvotePill = UIView()
        upvotePill.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.98, alpha: 1.0)
        upvotePill.layer.cornerRadius = 12
        upvotePill.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(upvotePill)

        let upvoteLabel = UILabel()
        upvoteLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        upvoteLabel.textColor = .secondaryLabel
        upvoteLabel.text = "\(Int.random(in: 1...20))"
        upvoteLabel.translatesAutoresizingMaskIntoConstraints = false
        upvotePill.addSubview(upvoteLabel)

        // Reply button
        let replyButton = UIButton(type: .system)
        replyButton.translatesAutoresizingMaskIntoConstraints = false
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "bubble.left")
        config.imagePadding = 4
        config.title = "Reply"
        config.baseForegroundColor = .secondaryLabel
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 11)
        replyButton.configuration = config
        replyButton.titleLabel?.font = .systemFont(ofSize: 11, weight: .medium)
        card.addSubview(replyButton)

        NSLayoutConstraint.activate([
            replyAvatar.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            replyAvatar.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            replyAvatar.widthAnchor.constraint(equalToConstant: 32),
            replyAvatar.heightAnchor.constraint(equalToConstant: 32),

            threadLine.topAnchor.constraint(equalTo: replyAvatar.bottomAnchor, constant: 4),
            threadLine.centerXAnchor.constraint(equalTo: replyAvatar.centerXAnchor),
            threadLine.widthAnchor.constraint(equalToConstant: 2),
            threadLine.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),

            nameLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 10),
            nameLabel.leadingAnchor.constraint(equalTo: replyAvatar.trailingAnchor, constant: 8),

            timeLabel.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            timeLabel.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 6),
            timeLabel.trailingAnchor.constraint(lessThanOrEqualTo: card.trailingAnchor, constant: -12),

            bodyLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 6),
            bodyLabel.leadingAnchor.constraint(equalTo: replyAvatar.trailingAnchor, constant: 8),
            bodyLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),

            upvotePill.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: 10),
            upvotePill.leadingAnchor.constraint(equalTo: replyAvatar.trailingAnchor, constant: 8),
            upvotePill.heightAnchor.constraint(equalToConstant: 24),
            upvotePill.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),

            upvoteLabel.centerXAnchor.constraint(equalTo: upvotePill.centerXAnchor),
            upvoteLabel.centerYAnchor.constraint(equalTo: upvotePill.centerYAnchor),
            upvotePill.widthAnchor.constraint(equalTo: upvoteLabel.widthAnchor, constant: 22),

            replyButton.centerYAnchor.constraint(equalTo: upvotePill.centerYAnchor),
            replyButton.leadingAnchor.constraint(equalTo: upvotePill.trailingAnchor, constant: 8),
        ])

        return card
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        if navigationController != nil {
            dismiss(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func sendTapped() {
        if !checkClubMembership() {
            showJoinClubAlert()
            return
        }

        let text = inputField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !text.isEmpty, let d = discussion else { return }
        delegate?.didPostReply(to: d.id, content: text)

        // Remove empty state if present
        repliesStack.arrangedSubviews.forEach { v in
            if let l = v as? UILabel { l.removeFromSuperview() }
        }

        let reply = BookDiscussionReply(id: UUID().uuidString, username: "You", avatarEmoji: "😊", content: text, timestamp: "Just now")
        let card = makeReplyCard(reply)
        repliesStack.addArrangedSubview(card)

        // Update comment count
        if let currentCount = Int(commentCountLabel.text ?? "0") {
            commentCountLabel.text = "\(currentCount + 1)"
        }

        inputField.text = ""
        inputField.resignFirstResponder()

        // Scroll to bottom
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            let bottom = CGPoint(x: 0, y: max(0, self.scrollView.contentSize.height - self.scrollView.bounds.height + self.scrollView.contentInset.bottom))
            self.scrollView.setContentOffset(bottom, animated: true)
        }
    }

    // MARK: - Helpers

    private func colorFromHex(_ hex: String) -> UIColor {
        var hexClean = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexClean = hexClean.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: hexClean).scanHexInt64(&rgb)
        return UIColor(
            red: CGFloat((rgb >> 16) & 0xFF) / 255.0,
            green: CGFloat((rgb >> 8) & 0xFF) / 255.0,
            blue: CGFloat(rgb & 0xFF) / 255.0,
            alpha: 1.0
        )
    }

    // MARK: - Keyboard

    @objc private func keyboardWillShow(_ n: Notification) {
        guard let frame = n.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = n.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        let safeBottom = view.safeAreaInsets.bottom
        inputBottomConstraint.constant = -(frame.height - safeBottom)
        UIView.animate(withDuration: duration) { self.view.layoutIfNeeded() }
    }

    @objc private func keyboardWillHide(_ n: Notification) {
        guard let duration = n.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        inputBottomConstraint.constant = 0
        UIView.animate(withDuration: duration) { self.view.layoutIfNeeded() }
    }
}
