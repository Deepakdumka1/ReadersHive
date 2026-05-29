//
//  ChatRoomCollectionViewCell.swift
//  Club
//
//  Created by Manas  on 01/03/26.
//

import UIKit

class ChatRoomCollectionViewCell: UICollectionViewCell {
    
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var iconContainer: UIView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var chevronImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = .clear
        contentView.layer.masksToBounds = false
        backgroundColor = .clear
        layer.masksToBounds = false

        // Shadow on container
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.08
        containerView.layer.shadowRadius = 8
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.masksToBounds = false

        // Set chevron SF Symbol
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        chevronImageView.image = UIImage(systemName: "chevron.right", withConfiguration: config)
    }

    func configure(with chatRoom: ChatRoom) {
        titleLabel.text = chatRoom.title
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        iconImageView.image = UIImage(systemName: chatRoom.icon, withConfiguration: config)
    }
}
