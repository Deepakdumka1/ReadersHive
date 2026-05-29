//
//  bookDetailCell1.swift
//  shelf_start
//
//  Created by Pawan Bisht on 12/02/26.
//

import UIKit

class bookDetailCell1: UITableViewCell {

    @IBOutlet weak var bookImageView: UIImageView!
        @IBOutlet weak var bookNameLabel: UILabel!
        @IBOutlet weak var bookAuthorLabel: UILabel!
        @IBOutlet weak var bookDescriptionLabel: UILabel!

        override func awakeFromNib() {
            super.awakeFromNib()

            bookImageView.layer.cornerRadius = 12
            bookImageView.clipsToBounds = true
      
                    contentView.layer.cornerRadius = 18
                    contentView.layer.masksToBounds = true
                    layer.cornerRadius = 18
                    layer.masksToBounds = false
                    layer.shadowColor = UIColor.black.cgColor
                    layer.shadowOpacity = 0.12
                    layer.shadowRadius = 10
                    layer.shadowOffset = CGSize(width: 0, height: 4)
        }

        
        func configure(with book: Book) {
            bookNameLabel.text = book.title
            bookAuthorLabel.text = book.author
            bookDescriptionLabel.text = book.description
            
            if book.coverImageURL.hasPrefix("http") {
                bookImageView.loadFromUrl(book.coverImageURL, placeholder: UIImage(systemName: "book"))
            } else {
                bookImageView.image = UIImage(named: book.coverImageURL) ?? UIImage(systemName: "book")
            }
        }

}
