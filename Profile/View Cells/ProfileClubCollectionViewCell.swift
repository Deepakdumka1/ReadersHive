//
//  ProfileClubCollectionViewCell.swift
//  Club
//

import UIKit

class ProfileClubCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var clubImageView: UIImageView!
    @IBOutlet weak var clubNameLabel: UILabel!
    @IBOutlet weak var membersIconImageView: UIImageView!
    @IBOutlet weak var membersCountLabel: UILabel!
    @IBOutlet weak var clubTypeLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    func configure(with clubName: String, membersCount: Int, type: String, imageName: String?) {
        clubNameLabel.text = clubName
        membersCountLabel.text = "\(membersCount)"
        clubTypeLabel.text = type
        if let img = imageName, !img.isEmpty, img.hasPrefix("http") {
            clubImageView.contentMode = .scaleAspectFill
            clubImageView.backgroundColor = .clear
            clubImageView.loadFromUrl(img)
        } else if let img = imageName, !img.isEmpty {
            clubImageView.contentMode = .scaleAspectFill
            clubImageView.backgroundColor = .clear
            clubImageView.image = UIImage(named: img)
        } else {
            clubImageView.contentMode = .center
            clubImageView.backgroundColor = .systemGray6
            clubImageView.tintColor = .systemGray3
            let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .regular)
            clubImageView.image = UIImage(systemName: "photo", withConfiguration: config)
        }
    }
    
    private func setupUI() {
        // Container styling
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 16
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.systemGray5.cgColor
        containerView.layer.masksToBounds = true
        
        // Setup shadow on the cell's layer
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 8
        layer.shadowOpacity = 0.05
        layer.masksToBounds = false
        
        // Force the imageView to stretch vertically instead of the stack view below it
        clubImageView.setContentHuggingPriority(.defaultLow, for: .vertical)
        clubImageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
    }
    
    
    //Configure Club Cell
}
