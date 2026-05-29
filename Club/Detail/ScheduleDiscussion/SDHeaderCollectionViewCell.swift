//
//  SDHeaderCollectionViewCell.swift
//  Club
//
//  Created by Manas  on 06/04/26.
//

import UIKit

class SDHeaderCollectionViewCell: UICollectionViewCell {

//    @IBOutlet weak var TotalAttendingLabel: UILabel!
    @IBOutlet weak var TitleLabel: UILabel!
    @IBOutlet weak var gradientView: UIView!
//    @IBOutlet weak var tagLabel: UILabel!

    @IBOutlet weak var avatarsStackView: UIStackView!
//    @IBOutlet weak var attendingLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configure(with discussion: Discussion) {
        TitleLabel.text = discussion.title
//        tagLabel.text = " LITERATURE EVENT "
//        attendingLabel.text = "+142 attending"
    }
}
