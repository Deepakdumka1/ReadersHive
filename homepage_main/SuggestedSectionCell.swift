import UIKit

class SuggestedSectionCell: UICollectionViewCell {

    @IBOutlet weak var collectionView: UICollectionView!
    
    var users: [SuggestedUser] = []
    weak var delegate: SuggestedUserCellDelegate?

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
            UINib(nibName: "SuggestedUserCell", bundle: nil),
            forCellWithReuseIdentifier: "SuggestedUserCell"
        )
    }

    func configure(with users: [SuggestedUser], delegate: SuggestedUserCellDelegate?) {
        self.users = users
        self.delegate = delegate
        collectionView.reloadData()
    }
    func addBottomSeparator() {
        let separator = UIView()
        separator.backgroundColor = UIColor.systemGray4
        separator.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(separator)
        
        let scale = traitCollection.displayScale > 0 ? traitCollection.displayScale : 2.0
        NSLayoutConstraint.activate([
            separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1 / scale)
        ])
    }
}

// MARK: - Inner Collection
extension SuggestedSectionCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, SuggestedUserCellDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return users.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "SuggestedUserCell",
            for: indexPath
        ) as! SuggestedUserCell
        
        cell.configureCell(with: users[indexPath.item], delegate: self)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: 160, height: 200)
    }

    // Forwarding Delegate Methods
    func didTapFollow(userId: String) {
        delegate?.didTapFollow(userId: userId)
    }

    func didTapClose(userId: String) {
        delegate?.didTapClose(userId: userId)
    }

    func didTapUser(userId: String) {
        delegate?.didTapUser(userId: userId)
    }
}
