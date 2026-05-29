//
//  SDMeetingLinkCollectionViewCell.swift
//  Club
//
//  Created by Manas  on 06/04/26.
//

import UIKit

class SDMeetingLinkCollectionViewCell: UICollectionViewCell {
    
    
    var onLaunchTapped: (() -> Void)?
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var meetIconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var linkLabel: UILabel!
    @IBOutlet weak var launchButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        containerView.layer.cornerRadius = 12
        containerView.clipsToBounds = true
        launchButton.layer.cornerRadius = 8
        launchButton.clipsToBounds = true
    }
    
    @IBAction func launchButtonTapped(_ sender: UIButton) {
        onLaunchTapped?()
    }
    
    private var meetingLink: String?

    func configure(with discussion: Discussion) {
        meetingLink = discussion.meetingLink
        
        guard let link = discussion.meetingLink else {
            titleLabel.text = "No Meeting Link"
            linkLabel.text = "-"
            return
        }
        
        linkLabel.text = link
        let lowerLink = link.lowercased()
        
        if lowerLink.contains("meet.google.com") {
            titleLabel.text = "Google Meet"
            meetIconImageView.image = UIImage(named: "google_meet_icon")
            
        } else if lowerLink.contains("zoom.us") {
            titleLabel.text = "Zoom"
            meetIconImageView.image = UIImage(named: "zoom_icon")
            
        } else if lowerLink.contains("teams.microsoft.com") {
            titleLabel.text = "Microsoft Teams"
            meetIconImageView.image = UIImage(named: "teams_icon")
            
        } else {
            titleLabel.text = "Meeting Link"
            meetIconImageView.image = UIImage(named: "link_icon")
        }
    }
}
