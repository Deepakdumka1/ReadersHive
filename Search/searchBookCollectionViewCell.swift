import UIKit

class searchBookCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var coverImageView: UIImageView!
   
   
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var tittleLabel: UILabel!
   
    override func awakeFromNib() {
        super.awakeFromNib()

        coverImageView.layer.cornerRadius = 10
        coverImageView.clipsToBounds = true
    }

    func configure(with book: Book) {
        tittleLabel.text = book.title
        authorLabel.text = book.author
        coverImageView.image = UIImage(named: book.coverImageURL)
    }
}
