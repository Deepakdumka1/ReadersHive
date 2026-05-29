//
//  FilterCollectionViewCell.swift
//  Club
//
//  Created by Manas  on 06/03/26.
//

import UIKit

class FilterCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var pillContainer: UIView!
    @IBOutlet weak var pillLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        // Border color needs CGColor, can't be done in XIB
        pillContainer.layer.borderColor = UIColor(red: 0.85, green: 0.85, blue: 0.88, alpha: 1.0).cgColor
    }

    func configure(with filter: Filter) {
        pillLabel.text = filter.title
        if filter.isSelected {
            pillContainer.backgroundColor = UIColor(red: 0.20, green: 0.20, blue: 0.35, alpha: 1.0)
            pillContainer.layer.borderColor = UIColor.clear.cgColor
            pillLabel.textColor = .white
        } else {
            pillContainer.backgroundColor = .white
            pillContainer.layer.borderColor = UIColor(red: 0.85, green: 0.85, blue: 0.88, alpha: 1.0).cgColor
            pillLabel.textColor = UIColor(red: 0.35, green: 0.35, blue: 0.45, alpha: 1.0)
        }
    }
}
