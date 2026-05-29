//
//  MyPostsHeaderCell.swift
//  Club
//
//  Created by GEU on 23/03/26.
//

import UIKit

class MyPostsHeaderCell: UICollectionReusableView {
    
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    func configure(title: String) {
        //        let configuration = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        //        let image = UIImage(systemName: "chevron.right", withConfiguration: configuration)?.withTintColor(.label, renderingMode: .alwaysOriginal)
        //
        //        let textAttachment = NSTextAttachment()
        //        textAttachment.image = image
        //
        //        let attributedString = NSMutableAttributedString(string: title + " ")
        //        attributedString.append(NSAttributedString(attachment: textAttachment))
        //
        //        titleLabel?.attributedText = attributedString
        
        titleLabel?.text = title
    }
}
