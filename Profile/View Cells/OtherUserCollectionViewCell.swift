//
//  OtherUserCollectionViewCell.swift
//  Club
//
//  Created by GEU on 25/03/26.
//

import UIKit

protocol OtherUserCardDelegate: AnyObject {
    func didTapFollowers()
    func didTapFollowing()
    func didTapFollowButton(cell: OtherUserCollectionViewCell)
    func didTapMessage(cell: OtherUserCollectionViewCell)
    func shouldPromptFollowFirst()
}


class OtherUserCollectionViewCell: UICollectionViewCell {
    
    weak var delegate: OtherUserCardDelegate?
    
    private var isFollowed: Bool = false
    
    // Outlets
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var followersButton: UIButton!
    @IBOutlet weak var followingButton: UIButton!
    @IBOutlet weak var userBioLabel: UILabel!
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var messageButton: UIButton!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
        bindActions()
    }
    
    
    // Reset state
    override func prepareForReuse() {
        super.prepareForReuse()
        isFollowed = false
    }
    
    
    //Setup
    private func setupUI() {
        containerView.layer.cornerRadius = 24
        containerView.layer.masksToBounds = true
        
        userImageView.layer.cornerRadius = userImageView.frame.height/2
        userImageView.clipsToBounds = true
        userImageView.layer.borderWidth = 3
        userImageView.layer.borderColor = UIColor.systemBackground.cgColor
        
        followButton.layer.cornerRadius = 14
        followButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        
        messageButton.layer.cornerRadius = 14
        messageButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
    }
    
    
    //Connects UI events
    private func bindActions() {
        followersButton.addAction(UIAction { [weak self] _ in
            self?.delegate?.didTapFollowers()
        }, for: .touchUpInside)
        
        followingButton.addAction(UIAction { [weak self] _ in
            self?.delegate?.didTapFollowing()
        }, for: .touchUpInside)
        
        followButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.delegate?.didTapFollowButton(cell: self)
        }, for: .touchUpInside)
        
        messageButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            
            if !self.isFollowed {
                self.delegate?.shouldPromptFollowFirst()
                return
            }
            
            self.delegate?.didTapMessage(cell: self)
            
        }, for: .touchUpInside)
    }
    
    
    //Configure function
    func configure(name: String, imageName: String?, followers: Int, following: Int, bio: String?, isFollowed: Bool) {
        self.isFollowed = isFollowed
        
        userImageView.loadFromUrl(imageName)
        
        nameLabel.text = name
        userBioLabel.text = bio ?? ""
        userBioLabel.font = .systemFont(ofSize: 15, weight: .medium)
        
        setStatButton(followersButton, count: followers, label: "followers")
        setStatButton(followingButton, count: following, label: "following")
        
        // Message button should always be enabled so the "Prompt Follow First" alert can fire
        messageButton.isEnabled = true
        
        // Follow button state
        if isFollowed {
            followButton.setTitle("Following", for: .normal)
            followButton.backgroundColor = .systemGray6
            followButton.setTitleColor(.label, for: .normal)
            
            // Message Visuals Active
            messageButton.backgroundColor = .systemGray6
            messageButton.setTitleColor(.label, for: .normal)
            messageButton.alpha = 1.0
            
        } else {
            followButton.setTitle("Follow", for: .normal)
            followButton.backgroundColor = .systemBlue
            followButton.setTitleColor(.white, for: .normal)
            
            // Message Visuals Disabled
            messageButton.backgroundColor = .systemGray6
            messageButton.setTitleColor(.systemGray2, for: .normal)
            messageButton.alpha = 0.6
        }
    }
    
    
    //Helper function -> Sets the count of followers and following
    private func setStatButton(_ button: UIButton, count: Int, label: String) {
        button.titleLabel?.numberOfLines = 2
        
        let countStr = NSAttributedString(
            string: "\(count)\n",
            attributes: [
                .font: UIFont.systemFont(ofSize: 18, weight: .semibold),
                .foregroundColor: UIColor.label
            ]
        )
        
        let labelStr = NSAttributedString(
            string: label,
            attributes: [
                .font: UIFont.systemFont(ofSize: 14, weight: .regular),
                .foregroundColor: UIColor.label
            ]
        )
        
        let combined = NSMutableAttributedString(attributedString: countStr)
        combined.append(labelStr)
        
        button.setAttributedTitle(combined, for: .normal)
    }
    
}


