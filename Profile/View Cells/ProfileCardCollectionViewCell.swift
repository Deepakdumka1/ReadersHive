//
//  ProfileCardCollectionViewCell.swift
//  Club
//
//  Created by GEU on 20/03/26.
//

import UIKit

protocol ProfileCardDelegate: AnyObject {
    func didTapFollowers()
    func didTapFollowing()
    func didTapProfileImage()
}

class ProfileCardCollectionViewCell: UICollectionViewCell {
    
    weak var delegate: ProfileCardDelegate?
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var followersButton: UIButton!
    @IBOutlet weak var followingButton: UIButton!
    @IBOutlet weak var bioLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
        
        followersButton.addAction(UIAction { [weak self] _ in
            self?.delegate?.didTapFollowers()
        }, for: .touchUpInside)
        
        followingButton.addAction(UIAction { [weak self] _ in
            self?.delegate?.didTapFollowing()
        }, for: .touchUpInside)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
        profileImageView.addGestureRecognizer(tap)
        profileImageView.isUserInteractionEnabled = true
    }
    
    @objc private func imageTapped() {
        delegate?.didTapProfileImage()
    }
    
    
    private func setupUI() {
        containerView.layer.cornerRadius = 20
        containerView.layer.masksToBounds = true
        
        profileImageView.layer.cornerRadius = profileImageView.frame.height / 2
    }
    
    
    func configure(name: String, username: String, followers: Int, following: Int, bio: String, imageName: String?) {
        if let imgName = imageName {
            if imgName.hasPrefix("http") {
                loadImage(from: imgName)
            } else if let image = UIImage(named: imgName) {
                profileImageView.image = image
                profileImageView.tintColor = .none
            } else {
                setDefaultImage()
            }
        } else {
            setDefaultImage()
        }
        
        nameLabel.text = name
        usernameLabel.text = username
        bioLabel.text = bio
        setStatButton(followersButton, count: followers, label: "followers")
        setStatButton(followingButton, count: following, label: "following")
    }
    
    private func setDefaultImage() {
        profileImageView.image = UIImage(systemName: "person.circle.fill")
        profileImageView.tintColor = .systemGray
    }
    
    private func loadImage(from urlString: String) {
        profileImageView.loadFromUrl(urlString)
    }
    
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
