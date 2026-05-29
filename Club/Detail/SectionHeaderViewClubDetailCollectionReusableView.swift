//
//  SectionHeaderViewClubDetailCollectionReusableView.swift
//  Club
//
//  Created by Manas  on 10/03/26.
//

import UIKit

protocol SectionHeaderDelegate: AnyObject {
    func didTapActionButton(inSection section: Int)
}

class SectionHeaderViewClubDetailCollectionReusableView: UICollectionReusableView {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!

    weak var delegate: SectionHeaderDelegate?
    var section: Int = 0

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        actionButton.isHidden = true
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
    }

    func configure(withTitle title: String, isAdmin: Bool = false) {
        titleLabel.text = title
        actionButton.isHidden = !isAdmin
    }

    @objc private func actionButtonTapped() {
        delegate?.didTapActionButton(inSection: section)
    }
}
