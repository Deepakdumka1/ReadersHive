//
//  SectionHeaderView.swift
//  Club
//
//  Created by GEU on 06/02/26.
//

import UIKit

class ClubSectionHeaderView: UICollectionReusableView {

    @IBOutlet var headerButton: UIButton!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var chevronImageView: UIImageView!
    @IBOutlet var countLabel: UILabel!

    var onHeaderButtonTapped: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func configure(with title: String, count: Int? = nil) {
        titleLabel.text = title
        if let count = count {
            countLabel.text = "\(count) Clubs"
            countLabel.isHidden = false
        } else {
            countLabel.isHidden = true
        }
    }

    @IBAction func ButtonClicked(_ sender: Any) {
        onHeaderButtonTapped?()
    }
}
