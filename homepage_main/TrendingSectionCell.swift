import UIKit

protocol TrendingSectionCellDelegate: AnyObject {
    func didTapTrendingBook(_ book: TrendingBook)
}

class TrendingSectionCell: UICollectionViewCell {

    @IBOutlet weak var collectionView: UICollectionView!
    
    var books: [TrendingBook] = []
    weak var delegate: TrendingSectionCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupCollectionView()
        addBottomSeparator()
    }

    func setupCollectionView() {
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 16
        
        collectionView.collectionViewLayout = layout
        collectionView.showsHorizontalScrollIndicator = false
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.register(
            UINib(nibName: "TrendingBookCollectionViewCell", bundle: nil),
            forCellWithReuseIdentifier: "TrendingBookCollectionViewCell"
        )
    }

    func configure(with books: [TrendingBook]) {
        self.books = books
        collectionView.reloadData()
    }
    func addBottomSeparator() {
        let separator = UIView()
        separator.backgroundColor = UIColor.systemGray4
        separator.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(separator)
        
        NSLayoutConstraint.activate([
            separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale)
        ])
    }
}

// MARK: - Collection inside cell
extension TrendingSectionCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return books.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "TrendingBookCollectionViewCell",
            for: indexPath
        ) as! TrendingBookCollectionViewCell
        
        cell.configureCell(with: books[indexPath.item])
        return cell
    }

    // 🔥 Size of each book card
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: 140, height: 220)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.didTapTrendingBook(books[indexPath.item])
    }
}
