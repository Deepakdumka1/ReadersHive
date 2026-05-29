//
//  CollectionViewCell.swift
//  shelf_start
//
//  Created by GEU on 10/02/26.
//

import UIKit

class BookShelfCollectionViewCell: UICollectionViewCell {
    @IBOutlet var authorName: UILabel!
    @IBOutlet var bookName: UILabel!
    @IBOutlet var imageView: UIImageView!
    
    @IBOutlet var index: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        imageView.layer.cornerRadius = 5
        imageView.layer.borderWidth = 0.5
    
        imageView.clipsToBounds = true
     
        imageView.layer.borderColor = UIColor.systemGray5.cgColor
    }
    func configure(with book: Book, position: Int) {
        authorName.text = book.author
        bookName.text = book.title
        index.text = "\(position)"
        imageView.image = UIImage(named: book.coverImageURL)
    }
       
    func showEmptyState(slot: Int) {

        bookName.text = "Empty Slot"
        authorName.text = "Add book to this list"
        index.text = "\(slot)"
   
        imageView.image = UIImage(systemName: "plus.square")
        imageView.tintColor = .systemGray4
        imageView.contentMode = .scaleAspectFit
        imageView.alpha = 0.6
    }
        
}
