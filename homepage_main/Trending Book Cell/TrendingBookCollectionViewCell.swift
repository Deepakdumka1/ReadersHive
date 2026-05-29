//
//  TrendingBookCollectionViewCell.swift
//  homepage_main
//
//  Created by Deepak Dumka on 13/02/26.
//

import UIKit

class TrendingBookCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = .clear
        self.contentView.backgroundColor = .clear
        if let containerView = self.contentView.subviews.first {
            containerView.backgroundColor = .clear
        }
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 16
        imageView.layer.masksToBounds = true
        // Initialization code
    }
    func configureCell(with book1: TrendingBook) {
        imageView.image = UIImage(named: book1.coverImage)
    }
    
}
