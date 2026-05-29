//
//  tagBookCollectionViewCell.swift
//  Club
//
//  Created by Pawan Bisht on 11/04/26.
//

import UIKit
private let imageCache = NSCache<NSString, UIImage>()
class BookCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var bookTitle: UILabel!
    
    
    @IBOutlet weak var authorName: UILabel!
    
    func configure(with book: Book) {
        
        bookTitle.text = book.title
        authorName.text = book.author
        
        // 🔥 Reset (important for reuse)
        imageView.image = UIImage(systemName: "book")
        imageView.tintColor = .systemGray4
        imageView.contentMode = .scaleAspectFit
        
        // 🔥 Handle both LOCAL + API
        if book.coverImageURL.starts(with: "http") {
            loadImage(urlString: book.coverImageURL)
        } else {
            imageView.image = UIImage(named: book.coverImageURL)
            imageView.contentMode = .scaleAspectFill
        }
    }
    func loadImage(urlString: String) {
        
        // 🔥 CACHE CHECK
        if let cached = imageCache.object(forKey: urlString as NSString) {
            imageView.image = cached
            imageView.contentMode = .scaleAspectFill
            return
        }
        
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            
            guard let data = data,
                  let image = UIImage(data: data) else { return }
            
            // 🔥 SAVE CACHE
            imageCache.setObject(image, forKey: urlString as NSString)
            
            DispatchQueue.main.async {
                self?.imageView.image = image
                self?.imageView.contentMode = .scaleAspectFill
            }
            
        }.resume()
    }}
