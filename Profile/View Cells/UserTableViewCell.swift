//
//  UserTableViewCell.swift
//  Club
//
//  Created by GEU on 27/03/26.
//

import UIKit

class UserTableViewCell: UITableViewCell {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var userFullNameLabel: UILabel!
    @IBOutlet weak var followMessageButton: UIButton!
    
    var onActionTap: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupViews()
        setupActions()
    }
    
    
    private func setupViews() {
         containerView.layer.cornerRadius = 12
         containerView.layer.masksToBounds = true
         
         userImageView.layer.cornerRadius = userImageView.frame.height / 2
         userImageView.clipsToBounds = true
         
         followMessageButton.layer.cornerRadius = 16
         
         // Custom Separator
         let separator = UIView()
         separator.backgroundColor = UIColor.systemGray4
         separator.translatesAutoresizingMaskIntoConstraints = false
         contentView.addSubview(separator)

         NSLayoutConstraint.activate([
             separator.leadingAnchor.constraint(equalTo: userImageView.trailingAnchor, constant: 12),
             separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
             separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
             separator.heightAnchor.constraint(equalToConstant: 0.5)
         ])
    }
    
    
    private func setupActions() {
        followMessageButton.addAction(UIAction { [weak self] _ in
            self?.onActionTap?()
        }, for: .touchUpInside)
    }

    
    func configure(profile: Profile, isFollowing: Bool) {
        userFullNameLabel.text = profile.fullName
        
        let username = profile.username.hasPrefix("@") ? profile.username : "@\(profile.username)"
        usernameLabel.text = username
        
        if let avatarUrl = profile.avatarUrl, let img = UIImage(named: avatarUrl) {
            userImageView.image = img
        } else {
            userImageView.image = UIImage(systemName: "person.circle.fill")
        }
        
        if isFollowing {
            // Message style (light gray)
            followMessageButton.setTitle("Message", for: .normal)
            followMessageButton.backgroundColor = UIColor.systemGray5
            followMessageButton.setTitleColor(.black, for: .normal)
        } else {
            // Follow Back style (blue)
            followMessageButton.setTitle("Follow Back", for: .normal)
            followMessageButton.backgroundColor = UIColor.systemBlue
            followMessageButton.setTitleColor(.white, for: .normal)
        }
    }
    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
