//
//  ChatRoomMessageCell.swift
//  Club
//

import UIKit

class ChatRoomMessageCell: UITableViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var bubbleView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet var leadingConstraint: NSLayoutConstraint!
    @IBOutlet var trailingConstraint: NSLayoutConstraint!
    @IBOutlet var timeLabelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var timeLabelTrailingConstraint: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
        avatarImageView.layer.cornerRadius = 20
        avatarImageView.clipsToBounds = true

        bubbleView.layer.cornerRadius = 14
        bubbleView.clipsToBounds = true
    }

    func configure(with message: ChatRoomMessage) {
        messageLabel.text = message.text
        timeLabel.text = message.time

        if message.isMine {
            // Right aligned
            avatarImageView.isHidden = true
            nameLabel.isHidden = true

            leadingConstraint.isActive = false
            trailingConstraint.isActive = true

            timeLabelLeadingConstraint.isActive = false
            timeLabelTrailingConstraint.isActive = true

            bubbleView.backgroundColor = UIColor(red: 0.55, green: 0.24, blue: 0.88, alpha: 1.0)
            messageLabel.textColor = .white
            nameLabel.text = ""

        } else {
            // Left aligned
            avatarImageView.isHidden = false
            nameLabel.isHidden = false

            trailingConstraint.isActive = false
            leadingConstraint.isActive = true

            timeLabelTrailingConstraint.isActive = false
            timeLabelLeadingConstraint.isActive = true

            bubbleView.backgroundColor = .systemGray6
            messageLabel.textColor = .label
            nameLabel.text = message.name

            if let urlStr = message.avatarUrl, !urlStr.isEmpty, urlStr.hasPrefix("http") {
                avatarImageView.loadFromUrl(urlStr)
            } else {
                let colors: [UIColor] = [.systemRed, .systemGreen, .systemOrange, .systemBlue, .systemPurple, .systemTeal]
                let index = abs(message.name.hashValue) % colors.count
                avatarImageView.backgroundColor = colors[index]
                avatarImageView.image = UIImage(systemName: "person.circle.fill")
                avatarImageView.tintColor = .white
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
//        leadingConstraint.isActive = false
//        trailingConstraint.isActive = false
        avatarImageView.isHidden = false
        nameLabel.isHidden = false
    }
}
