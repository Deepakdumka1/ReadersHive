//
//  MessageTableViewCell.swift
//  FinalMessageNavigator
//
//  Created by GEU on 14/02/26.
//

import UIKit

class MessageTableViewCell: UITableViewCell {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var unreadDot: UIView!
    @IBOutlet weak var avatarImage: UIImageView!
    @IBOutlet weak var fullName: UILabel!
    @IBOutlet weak var lastMessage: UILabel!
    @IBOutlet weak var timeStamp: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupStyles()
        
        // Prevent last message snippet from exceeding visual bounds
        lastMessage.translatesAutoresizingMaskIntoConstraints = false
        lastMessage.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -16).isActive = true
        lastMessage.lineBreakMode = .byTruncatingTail
    }

    
    override func layoutSubviews() {
        super.layoutSubviews()

        avatarImage.layer.cornerRadius = avatarImage.frame.height / 2
        unreadDot.layer.cornerRadius = unreadDot.frame.height / 2
        
        containerView.layer.shadowPath = UIBezierPath(roundedRect: containerView.bounds, cornerRadius: 16).cgPath
    }
    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Use .systemBackground (white/black depending on dark mode) instead of .clear
        // .clear makes the drop shadow bleed straight through the cell!
        containerView.backgroundColor = selected ? .systemGray5 : .systemBackground
    }
    
    
    private func setupStyles() {
           
        // Ensures the initial state has a solid background
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 16
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.1
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowRadius = 4
        containerView.layer.masksToBounds = false
        // Required for shadow to show
        
        unreadDot.backgroundColor = .systemBlue

        fullName.textColor = .label
        lastMessage.textColor = .secondaryLabel
        timeStamp.textColor = .tertiaryLabel
    }
    
    // MARK: - Configuration
    func configure(with chat: Conversation) {
        fullName.text = chat.otherUserName
        avatarImage.loadFromUrl(chat.avatarImage)
        lastMessage.text = chat.lastMessageSnippet
        timeStamp.text = chat.lastMessageTime
        
        let isUnread = chat.messages.last?.isRead == false
        
        // Dynamic Type compliant unread styling
        if isUnread {
            fullName.font = UIFont.preferredFont(forTextStyle: .headline) // Naturally semibold
            lastMessage.textColor = .label // Darker
            unreadDot.isHidden = false
        } else {
            fullName.font = UIFont.preferredFont(forTextStyle: .body) // Regular weight
            lastMessage.textColor = .secondaryLabel // Lighter preview text
            unreadDot.isHidden = true
        }
    }
}
