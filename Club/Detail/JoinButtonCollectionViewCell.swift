//
//  JoinButtonCollectionViewCell.swift
//  Club
//
//  Created by Manas  on 07/03/26.
//

import UIKit


class JoinButtonCollectionViewCell: UICollectionViewCell {
    
    weak var delegate: JoinDelegate?
    var club: Club?
    
    @IBOutlet weak var joinButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        // Shadows can't be set in XIB
        joinButton.layer.shadowColor = UIColor.black.cgColor
        joinButton.layer.shadowOpacity = 0.15
        joinButton.layer.shadowRadius = 8
        joinButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        joinButton.clipsToBounds = false
    }
    
    func configure(isAdmin: Bool, isMember: Bool) {

        if isAdmin {
            joinButton.setTitle("Schedule Discussion", for: .normal)
            let darkBlue = UIColor(red: 0.0, green: 0.3, blue: 0.7, alpha: 1.0)
            joinButton.backgroundColor = darkBlue
            joinButton.setTitleColor(.white, for: .normal)
        } else if isMember {
            joinButton.setTitle("Joined", for: .normal)
            let darkBlue = UIColor(red: 0.0, green: 0.3, blue: 0.7, alpha: 1.0)
            joinButton.backgroundColor = darkBlue
            joinButton.setTitleColor(.white, for: .normal)
        }
        
        else {
            joinButton.setTitle("Join Club", for: .normal)
//            joinButton.backgroundColor = UIColor.systemBlue
//            joinButton.setTitleColor(.white, for: .normal)
        }
    }
    
    @IBAction func joinButtonTapped(_ sender: UIButton) {
        guard let clubId = club?.id else { return }
        delegate?.didTapJoin(clubId: clubId)
    }
}

