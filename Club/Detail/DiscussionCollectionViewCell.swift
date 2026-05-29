//
//  DiscussionCollectionViewCell.swift
//  Club
//
//  Created by Manas  on 06/03/26.
//

import UIKit

class DiscussionCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var avatarView: UIView!
    @IBOutlet weak var avatarLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var previewLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = .clear
        contentView.layer.masksToBounds = false
        backgroundColor = .clear
        layer.masksToBounds = false

        // Shadow on container
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.08
        containerView.layer.shadowRadius = 10
        containerView.layer.shadowOffset = CGSize(width: 0, height: 3)
        containerView.layer.masksToBounds = false
    }

    func configure(with post: DiscussionPost) {
        titleLabel.text = post.title
        previewLabel.text = post.content
        avatarLabel.text = String(post.authorName.prefix(1)).uppercased()
        authorLabel.isHidden = true
    }

//        let attributed = NSMutableAttributedString()
//        attributed.append(NSAttributedString(
//            string: "by ",
//            attributes: [
//                .foregroundColor: UIColor(red: 0.55, green: 0.55, blue: 0.60, alpha: 1.0),
//                .font: UIFont.systemFont(ofSize: 11, weight: .regular)
//            ]))
//        attributed.append(NSAttributedString(
//            string: post.authorName,
//            attributes: [
////                .foregroundColor: colorFromHex(post.avatarColorHex),
//                .font: UIFont.systemFont(ofSize: 11, weight: .semibold)
//            ]))
//        attributed.append(NSAttributedString(
//            string: " • \(post.timeAgo)",
//            attributes: [
//                .foregroundColor: UIColor(red: 0.55, green: 0.55, blue: 0.60, alpha: 1.0),
//                .font: UIFont.systemFont(ofSize: 11, weight: .regular)
//            ]))
//        authorLabel.attributedText = attributed

//    private func colorFromHex(_ hex: String) -> UIColor {
//        var hexClean = hex.trimmingCharacters(in: .whitespacesAndNewlines)
//        hexClean = hexClean.replacingOccurrences(of: "#", with: "")
//        var rgb: UInt64 = 0
//        Scanner(string: hexClean).scanHexInt64(&rgb)
//        return UIColor(
//            red: CGFloat((rgb >> 16) & 0xFF) / 255.0,
//            green: CGFloat((rgb >> 8) & 0xFF) / 255.0,
//            blue: CGFloat(rgb & 0xFF) / 255.0,
//            alpha: 1.0
//        )
//    }
}
