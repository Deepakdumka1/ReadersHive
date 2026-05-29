//
//  ClubCollectionViewCell.swift
//  Club
//
//  Created by GEU on 04/02/26.
//

import UIKit


protocol JoinDelegate: AnyObject {
    func didTapJoin(clubId: String)
}

class ClubCollectionViewCell: UICollectionViewCell {
    
    weak var delegate: JoinDelegate?
    var club: Club?
//    var clubdata: ClubDetailData?
    
    @IBOutlet var language: UILabel!
    @IBOutlet var theme: UILabel!
    @IBOutlet var number: UILabel!
    @IBOutlet var clubDescription: UILabel!
    @IBOutlet var ClubTitle: UILabel!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var containerView: UIView!
    @IBOutlet var joinButton: UIButton!
    @IBOutlet var memberIconImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Content view clips to rounded corners
        contentView.layer.cornerRadius = 18
        contentView.layer.masksToBounds = true
        
        // Container also rounds for the white background
        containerView.layer.cornerRadius = 18
        containerView.layer.masksToBounds = true
        
        // Shadow on the cell layer itself (not clipped)
        layer.cornerRadius = 18
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.12
        layer.shadowRadius = 10
        layer.shadowOffset = CGSize(width: 0, height: 4)
        
        // Style the Join button as a small brown pill
        joinButton.backgroundColor = UIColor(
            red: 0.0,
            green: 102/255,
            blue: 204/255,
            alpha: 1.0
        )
        
        joinButton.setTitleColor(.white, for: .normal)
        joinButton.layer.cornerRadius = 11
        joinButton.layer.masksToBounds = true
        joinButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 11)
        if #available(iOS 15.0, *) {
            var config = joinButton.configuration ?? UIButton.Configuration.plain()
            config.contentInsets = NSDirectionalEdgeInsets(top: 3, leading: 10, bottom: 3, trailing: 10)
            joinButton.configuration = config
        } else {
            joinButton.contentEdgeInsets = UIEdgeInsets(top: 3, left: 10, bottom: 3, right: 10)
        }
        
        // Position Join button next to title programmatically (XIB constraints get stripped)
        joinButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            joinButton.centerYAnchor.constraint(equalTo: ClubTitle.centerYAnchor),
            joinButton.leadingAnchor.constraint(equalTo: ClubTitle.trailingAnchor, constant: 8),
            joinButton.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -8)
        ])
        // Let title compress so button fits
        ClubTitle.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        joinButton.setContentHuggingPriority(.required, for: .horizontal)
        
        // Round top corners of image
        imageView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        imageView.layer.cornerRadius = 18
        imageView.layer.masksToBounds = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Keep shadow path in sync with bounds for performance
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: 18).cgPath
    }
    
    func configureCell(club: Club) {
        self.club = club
        if let path = club.imagePath, !path.isEmpty {
            if path.hasPrefix("http") {
                imageView.loadFromUrl(path, placeholder: nil)
            } else if let img = UIImage(named: path) {
                imageView.image = img
            } else if let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let fileURL = docURL.appendingPathComponent(path)
                imageView.image = UIImage(contentsOfFile: fileURL.path)
            }
        } else {
            imageView.image = nil
        }
        ClubTitle.text = club.name
        clubDescription.text = club.description
        language.text = club.language
        theme.text = club.category?.displayName
        
        let count = club.members?.count ?? club.memberCount ?? 0
        number.text = String(count)
        
        // Show Join or Joined state based on membership
        let joined = isUserMember(club)
        joinButton.isHidden = false
        if joined {
            joinButton.setTitle("Joined", for: .normal)
            joinButton.backgroundColor = .systemGray3
            joinButton.setTitleColor(.darkGray, for: .normal)
            joinButton.isUserInteractionEnabled = false
        } else {
            joinButton.setTitle("Join", for: .normal)
            joinButton.backgroundColor = UIColor(
                red: 0.0,
                green: 102/255,
                blue: 204/255,
                alpha: 1.0
            )
            joinButton.setTitleColor(.white, for: .normal)
            joinButton.isUserInteractionEnabled = true
        }
    }
    
    
    
    @IBAction func joinButtonTapped(_ sender: UIButton) {
        guard let clubId = club?.id else { return }
        delegate?.didTapJoin(clubId: clubId)
    }
}

