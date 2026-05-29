//
//  searchheader.swift
//  Club
//
//  Created by Pawan Bisht on 15/04/26.
//

import UIKit

class searchheader: UICollectionReusableView {
    
    @IBOutlet weak var headerLabel: UILabel!
  //  @IBOutlet var headerButton: UIButton!

        var buttonAction: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

    }
 
   
   //  @IBAction func headerButtonTapped(_ sender: UIButton) {
         
         
     
    func configure(title: String, section: Int) {
        headerLabel.text = title
//                sectionIndex = section
        }
}
