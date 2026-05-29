//
//  BooksCollectionViewCell.swift
//  Club
//
//  Created by GEU on 16/03/26.
//

import UIKit
class BooksCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var bookTitle: UILabel!
    @IBOutlet weak var bookAuthor: UILabel!
    
    private static let imageCache = NSCache<NSString, UIImage>()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        coverImageView.layer.cornerRadius = 8
        coverImageView.clipsToBounds = true
    }
    
    func configure(with book: Book) {
        
        bookTitle.text = book.title
        bookAuthor.text = book.author
        
        // 🔥 Reset (important)
        coverImageView.image = UIImage(systemName: "book")
        coverImageView.tintColor = .systemGray4
        coverImageView.contentMode = .scaleAspectFit
        
        loadImage(urlString: book.coverImageURL)
    }
    
    private func loadImage(urlString: String) {
        
        // 🔥 FIX HTTP → HTTPS
        let secureURL = urlString.replacingOccurrences(of: "http://", with: "https://")
        
        // 🔥 CACHE
        if let cached = Self.imageCache.object(forKey: secureURL as NSString) {
            coverImageView.image = cached
            coverImageView.contentMode = .scaleAspectFill
            return
        }
        
        guard let url = URL(string: secureURL) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            
            guard let data = data,
                  let image = UIImage(data: data) else { return }
            
            Self.imageCache.setObject(image, forKey: secureURL as NSString)
            
            DispatchQueue.main.async {
                self?.coverImageView.image = image
                self?.coverImageView.contentMode = .scaleAspectFill
            }
            
        }.resume()
    }
}
