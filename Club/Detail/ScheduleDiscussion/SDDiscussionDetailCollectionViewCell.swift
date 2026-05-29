//
//  SDDiscussionDetailCollectionViewCell.swift
//  Club
//
//  Created by Manas  on 06/04/26.
//

import UIKit

class SDDiscussionDetailCollectionViewCell: UICollectionViewCell {
    

    @IBOutlet weak var HostNameLabel: UILabel!
    @IBOutlet weak var TimeLabel: UILabel!
    @IBOutlet weak var DateLabel: UILabel!
    var onHostTapped: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        HostNameLabel.isUserInteractionEnabled = true
        HostNameLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(hostTapped)))
        HostNameLabel.textColor = .systemBlue
    }
    
    @objc private func hostTapped() {
        onHostTapped?()
    }
    
    func configure(with discussion: Discussion, hostName: String?) {
        HostNameLabel.text = hostName ?? discussion.createdBy
        DateLabel.text = discussion.date
        TimeLabel.text = discussion.time
    }
}
