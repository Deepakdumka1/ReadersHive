//
//  ScheduleDiscussionCollectionViewCell.swift
//  Club
//
//  Created by Manas  on 06/03/26.
//

import UIKit

class ScheduleDiscussionCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var scheduledDot: UIView!
    @IBOutlet weak var scheduledLabel: UILabel!
    @IBOutlet weak var bellButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var avatarStackContainer: UIView!
    @IBOutlet weak var attendingLabel: UILabel!


    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    
    func configure(with data: Discussion) {
        titleLabel.text = data.title
        subtitleLabel.text = data.title
        scheduledLabel.text = data.date
        
        
        
        
    }

}
