//
//  UserCollectionViewCell.swift
//  Club
//
//  Created by Pawan Bisht on 02/04/26.
//

import UIKit

class UserCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var profileImageView: UIImageView!
       @IBOutlet weak var usernameLabel: UILabel!
       @IBOutlet weak var fullNameLabel: UILabel!
       @IBOutlet weak var closeButton: UIButton!

       override func awakeFromNib() {
           super.awakeFromNib()

           profileImageView.layer.cornerRadius = 24
           profileImageView.clipsToBounds = true
       }

    var onCloseTap: (() -> Void)?

    @IBAction func CloseActionButton(_ sender: Any) {
        onCloseTap?()
    }
    func configure(with user: Profile) {
           usernameLabel.text = user.username
           fullNameLabel.text = user.fullName

           if let avatar = user.avatarUrl {
               profileImageView.image = UIImage(named: avatar)
           } else {
               profileImageView.image = UIImage(systemName: "person.circle.fill")
           }
       }
}
