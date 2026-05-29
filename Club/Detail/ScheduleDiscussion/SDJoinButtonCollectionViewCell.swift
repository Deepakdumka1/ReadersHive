//
//  SDJoinButtonCollectionViewCell.swift
//  Club
//
//  Created by Manas  on 06/04/26.
//

import UIKit

class SDJoinButtonCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var joinButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        joinButton.layer.shadowColor = UIColor.black.cgColor
        joinButton.layer.shadowOpacity = 0.15
        joinButton.layer.shadowRadius = 8
        joinButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        joinButton.clipsToBounds = false
    }
    
    func configure(discussion: Discussion) {
        updateCountdown(discussion: discussion)

    }
    
    func getDiscussionDate(from discussion: Discussion) -> Date? {
        guard let date = discussion.date,
              let time = discussion.time else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d yyyy h:mm a"
        
        let fullString = "\(date) 2026 \(time)" //  Replace 2026 if dynamic
        return formatter.date(from: fullString)
    }
    
    func timeRemaining(to date: Date) -> String {
        let now = Date()
        
        if now >= date {
            joinButton.layer.backgroundColor = UIColor.systemGreen.cgColor
            return " Live Now"
            
        }
        
        let diff = Calendar.current.dateComponents([.day, .hour, .minute], from: now, to: date)
        
        if let day = diff.day, day > 0 {
            return "Starts in \(day)d \(diff.hour ?? 0)h"
        } else if let hour = diff.hour, hour > 0 {
            return "Starts in \(hour)h \(diff.minute ?? 0)m"
        } else {
            return "Starts in \(diff.minute ?? 0)m"
        }
    }
    
    func updateCountdown(discussion: Discussion) {
        guard let discussionDate = getDiscussionDate(from: discussion) else {
            joinButton.setTitle("Joined", for: .normal)
            return
        }
        
        let text = timeRemaining(to: discussionDate)
        joinButton.setTitle(text, for: .normal)
    }
}
