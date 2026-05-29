//
//  BookDiscussionCell.swift
//  Club
//
//  Created by Antigravity on 28/04/26.
//
//  Programmatic UITableViewCell for Reddit-style discussion posts
//  in the book card Community tab. Includes avatar, username, tag badge,
//  timestamp, content, spoiler overlay, 3-dot menu, and reply button.
//

import UIKit

// MARK: - Delegate

protocol BookDiscussionCellDelegate: AnyObject {
    func didTapReply(on discussion: BookDiscussion)
    func didTapRevealSpoiler(on discussion: BookDiscussion)
    func didTapMoreMenu(on discussion: BookDiscussion, sourceView: UIView)
}

// MARK: - Cell

class BookDiscussionCell: UITableViewCell {
    
    static let reuseId = "BookDiscussionCell"
    
    weak var delegate: BookDiscussionCellDelegate?
    private var discussion: BookDiscussion?
    
    // MARK: - UI Elements
    
    /// Card container with shadow and rounded corners.
    private let cardView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .white
        v.layer.cornerRadius = 16
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.06
        v.layer.shadowRadius = 12
        v.layer.shadowOffset = CGSize(width: 0, height: 4)
        v.layer.masksToBounds = false
        return v
    }()
    
    /// Emoji-based circular avatar.
    private let avatarLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 24)
        l.textAlignment = .center
        l.backgroundColor = UIColor(red: 0.95, green: 0.93, blue: 0.98, alpha: 1.0)
        l.layer.cornerRadius = 22
        l.layer.masksToBounds = true
        return l
    }()
    
    /// Username.
    private let usernameLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 15, weight: .semibold)
        l.textColor = .label
        return l
    }()
    
    /// Tag badge (pill with emoji + text).
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
        l.font = .systemFont(ofSize: 11, weight: .semibold)
        l.textColor = .white
        return l
    }()
    
    /// Timestamp.
    private let timestampLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 12, weight: .regular)
        l.textColor = .secondaryLabel
        return l
    }()
    
    /// 3-dot menu button.
    private let moreButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        b.setImage(UIImage(systemName: "ellipsis", withConfiguration: config), for: .normal)
        b.tintColor = .secondaryLabel
        return b
    }()
    
    /// Content text.
    private let contentLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.textColor = UIColor(red: 0.20, green: 0.20, blue: 0.25, alpha: 1.0)
        l.numberOfLines = 0
        return l
    }()
    
    /// Spoiler overlay container.
    private let spoilerOverlay: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.97, alpha: 1.0)
        v.layer.cornerRadius = 12
        v.layer.masksToBounds = true
        v.isUserInteractionEnabled = true
        return v
    }()
    
    /// Spoiler icon.
    private let spoilerIcon: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .light)
        iv.image = UIImage(systemName: "eye.slash", withConfiguration: config)
        iv.tintColor = UIColor(red: 0.75, green: 0.75, blue: 0.78, alpha: 1.0)
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    /// Spoiler label.
    private let spoilerLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "SPOILER HIDDEN"
        l.font = .systemFont(ofSize: 12, weight: .semibold)
        l.textColor = UIColor(red: 0.70, green: 0.70, blue: 0.73, alpha: 1.0)
        l.textAlignment = .center
        l.setContentHuggingPriority(.required, for: .vertical)
        return l
    }()
    
    // MARK: - Init
    
    // MARK: - Init
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupActions()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupActions()
    }
    
    // MARK: - Setup UI
    
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        contentView.addSubview(cardView)
        cardView.addSubview(avatarLabel)
        cardView.addSubview(usernameLabel)
        cardView.addSubview(tagBadge)
        tagBadge.addSubview(tagLabel)
        cardView.addSubview(timestampLabel)
        cardView.addSubview(moreButton)
        cardView.addSubview(contentLabel)
        cardView.addSubview(spoilerOverlay)
        spoilerOverlay.addSubview(spoilerIcon)
        spoilerOverlay.addSubview(spoilerLabel)
        
        NSLayoutConstraint.activate([
            // Card
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            
            // Avatar
            avatarLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            avatarLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            avatarLabel.widthAnchor.constraint(equalToConstant: 44),
            avatarLabel.heightAnchor.constraint(equalToConstant: 44),
            
            // Username
            usernameLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            usernameLabel.leadingAnchor.constraint(equalTo: avatarLabel.trailingAnchor, constant: 12),
            usernameLabel.trailingAnchor.constraint(lessThanOrEqualTo: moreButton.leadingAnchor, constant: -8),
            
            // Tag badge
            tagBadge.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 4),
            tagBadge.leadingAnchor.constraint(equalTo: avatarLabel.trailingAnchor, constant: 12),
            
            tagLabel.topAnchor.constraint(equalTo: tagBadge.topAnchor, constant: 3),
            tagLabel.bottomAnchor.constraint(equalTo: tagBadge.bottomAnchor, constant: -3),
            tagLabel.leadingAnchor.constraint(equalTo: tagBadge.leadingAnchor, constant: 8),
            tagLabel.trailingAnchor.constraint(equalTo: tagBadge.trailingAnchor, constant: -8),
            
            // Timestamp — after tag badge
            timestampLabel.centerYAnchor.constraint(equalTo: tagBadge.centerYAnchor),
            timestampLabel.leadingAnchor.constraint(equalTo: tagBadge.trailingAnchor, constant: 6),
            timestampLabel.trailingAnchor.constraint(lessThanOrEqualTo: moreButton.leadingAnchor, constant: -8),
            
            // More button
            moreButton.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            moreButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            moreButton.widthAnchor.constraint(equalToConstant: 24),
            moreButton.heightAnchor.constraint(equalToConstant: 24),
            
            // Content
            contentLabel.topAnchor.constraint(equalTo: avatarLabel.bottomAnchor, constant: 12),
            contentLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            contentLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            
            // Spoiler overlay (covers content area)
            spoilerOverlay.topAnchor.constraint(equalTo: contentLabel.topAnchor, constant: -4),
            spoilerOverlay.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            spoilerOverlay.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            spoilerOverlay.bottomAnchor.constraint(equalTo: contentLabel.bottomAnchor, constant: 4),
            spoilerOverlay.heightAnchor.constraint(greaterThanOrEqualToConstant: 80),
            
            spoilerIcon.centerXAnchor.constraint(equalTo: spoilerOverlay.centerXAnchor),
            spoilerIcon.centerYAnchor.constraint(equalTo: spoilerOverlay.centerYAnchor, constant: -10),
            
            spoilerLabel.topAnchor.constraint(equalTo: spoilerIcon.bottomAnchor, constant: 6),
            spoilerLabel.centerXAnchor.constraint(equalTo: spoilerOverlay.centerXAnchor),
            
            // Bottom constraint of card
            contentLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16),
        ])
    }
    
    // MARK: - Actions
    
    private func setupActions() {
        moreButton.addTarget(self, action: #selector(moreTapped), for: .touchUpInside)
        
        let spoilerTap = UITapGestureRecognizer(target: self, action: #selector(spoilerTapped))
        spoilerOverlay.addGestureRecognizer(spoilerTap)
    }
    
    @objc private func moreTapped() {
        guard let discussion = discussion else { return }
        delegate?.didTapMoreMenu(on: discussion, sourceView: moreButton)
    }
    
    @objc private func spoilerTapped() {
        guard let discussion = discussion else { return }
        delegate?.didTapRevealSpoiler(on: discussion)
    }
    
    // MARK: - Configure
    
    func configure(with discussion: BookDiscussion) {
        self.discussion = discussion
        
        avatarLabel.text = discussion.avatarEmoji
        usernameLabel.text = discussion.username
        tagLabel.text = discussion.tagLabel
        timestampLabel.text = "• " + discussion.timestamp
        contentLabel.text = discussion.content
        
        // Tag badge color from tag type
        let tagColor = colorFromHex(discussion.tag.colorHex)
        tagBadge.backgroundColor = tagColor.withAlphaComponent(0.12)
        tagLabel.textColor = tagColor
        
        // Spoiler handling
        if discussion.isSpoiler && !discussion.isRevealed {
            spoilerOverlay.isHidden = false
            contentLabel.alpha = 0  // Hide text behind overlay
        } else {
            spoilerOverlay.isHidden = true
            contentLabel.alpha = 1
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
    
    // MARK: - Reuse
    
    override func prepareForReuse() {
        super.prepareForReuse()
        avatarLabel.text = nil
        usernameLabel.text = nil
        tagLabel.text = nil
        timestampLabel.text = nil
        contentLabel.text = nil
        contentLabel.alpha = 1
        spoilerOverlay.isHidden = true
        discussion = nil
    }
}
