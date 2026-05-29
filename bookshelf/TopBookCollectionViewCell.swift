import UIKit

class TopBookCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var rankLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    private func setupUI() {
        // Cover Image
        coverImageView.layer.cornerRadius = 6 // Standard Apple Books corner radius for covers
        coverImageView.layer.borderWidth = 0.5
        coverImageView.layer.borderColor = UIColor.systemGray5.cgColor
        coverImageView.clipsToBounds = true
        coverImageView.contentMode = .scaleAspectFill
        

        // Fonts
        rankLabel.font = .systemFont(ofSize: 24, weight: .semibold)
        titleLabel.font = .systemFont(ofSize: 17, weight: .medium)
        authorLabel.font = .systemFont(ofSize: 15, weight: .regular)
        authorLabel.textColor = .secondaryLabel
    }
    
    private static let imageCache = NSCache<NSString, UIImage>()

    func configure(with book: Book, rank: Int) {
        rankLabel.text = "\(rank)"
        titleLabel.text = book.title
        authorLabel.text = book.author
        
        // Reset image
        coverImageView.image = UIImage(systemName: "book")
        coverImageView.tintColor = .systemGray4
        coverImageView.contentMode = .center
        
        loadImage(urlString: book.coverImageURL)
    }
    
    private func loadImage(urlString: String) {
        if urlString.isEmpty { return }
        
        let secureURL = urlString.replacingOccurrences(of: "http://", with: "https://")
        
        if let cached = Self.imageCache.object(forKey: secureURL as NSString) {
            coverImageView.image = cached
            coverImageView.contentMode = .scaleAspectFill
            return
        }
        
        guard let url = URL(string: secureURL) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data, let image = UIImage(data: data) else { return }
            Self.imageCache.setObject(image, forKey: secureURL as NSString)
            DispatchQueue.main.async {
                self?.coverImageView.image = image
                self?.coverImageView.contentMode = .scaleAspectFill
            }
        }.resume()
    }
    
    func showEmptyState(slot: Int) {

        titleLabel.text = "Empty Slot"
        authorLabel.text = "Add book to this list"
        rankLabel.text = "\(slot)"
   
        coverImageView.image = UIImage(systemName: "plus.square")
        coverImageView.tintColor = .systemGray4
        coverImageView.contentMode = .scaleAspectFit
        coverImageView.alpha = 0.6
    }
}
