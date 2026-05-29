//
//  SDDescriptionCollectionViewCell.swift
//  Club
//
//  Created by Manas  on 06/04/26.
//

import UIKit

class SDDescriptionCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var descriptionContainerView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        descriptionContainerView.layer.cornerRadius = 12
        descriptionContainerView.clipsToBounds = true
    }
    
    func configure(with discussion: Discussion) {
        descriptionLabel.text = discussion.description
    }
}
