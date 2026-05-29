//
//  SDSectionHeaderCollectionViewCell.swift
//  Club
//
//  Created by Manas  on 06/04/26.
//

import UIKit

class SDSectionHeaderCollectionViewCell: UICollectionReusableView {

    @IBOutlet weak var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configure(withTitle title: String) {
        titleLabel.text = title
    }
}
