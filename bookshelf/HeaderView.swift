//
//  SectionHeaderReusableView.swift
//  shelf_start
//
//  Created by GEU on 11/02/26.
//

import UIKit

class HeaderView: UICollectionReusableView {

    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet var headerButton: UIButton!

        var buttonAction: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

    }
 
    
     @IBAction func headerButtonTapped(_ sender: UIButton) {
         
         buttonAction?()
     }
    func configure(title: String, section: Int) {
        headerLabel.text = title
//                sectionIndex = section
        }
}
