//
//  CustomTableViewCell.swift
//  Club
//
//  Created by Manas  on 07/02/26.
//

import UIKit

class CustomTableViewCell: UITableViewCell {
    @IBOutlet weak var iconimageView: UIImageView!
    @IBOutlet weak var titlelabel: UILabel!
    @IBOutlet weak var desc: UILabel!
    @IBOutlet weak var genre: UILabel!
    @IBOutlet weak var view: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        
        // Optional: make backgrounds clean
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }
}
