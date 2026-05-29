//
//  recentbookHeaderView.swift
//  Club
//
//  Created by Pawan Bisht on 12/04/26.
//

import UIKit

class recentbookHeaderView: UICollectionReusableView {
    
    
    @IBOutlet weak var titleLabel: UILabel!
    func configure(title: String) {
        titleLabel.text = title
    }
}
