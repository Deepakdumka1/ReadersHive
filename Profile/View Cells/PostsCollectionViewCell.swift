//
//  PostsCollectionViewCell.swift
//  Club
//
//  Created by GEU on 20/03/26.
//

import UIKit

class PostsCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var postImageView: UIImageView!
    @IBOutlet weak var postDescriptionLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        containerView.layer.cornerRadius = 16
        containerView.layer.masksToBounds = true

        
        // Add subtle shadow to text for readability against images
        postDescriptionLabel.layer.shadowColor = UIColor.black.cgColor
        postDescriptionLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
        postDescriptionLabel.layer.shadowOpacity = 0.8
        postDescriptionLabel.layer.shadowRadius = 2
        postDescriptionLabel.layer.masksToBounds = false
    }
    
 
    func configure(with post: FeedPost) {
        if let postImage = post.postImage {
            postImageView.loadFromUrl(postImage, placeholder: nil)
            postImageView.backgroundColor = .clear
        } else {
            postImageView.image = nil
            postImageView.backgroundColor = .systemGray5
        }
        postDescriptionLabel.text = post.content
    }
}
