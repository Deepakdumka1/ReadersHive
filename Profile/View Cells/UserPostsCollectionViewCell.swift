import UIKit


protocol UserPostsCellDelegate: AnyObject {
    func didTapComment(on cell: UserPostsCollectionViewCell)
    func didTapEdit(on cell: UserPostsCollectionViewCell)
    func didTapShare(on cell: UserPostsCollectionViewCell)
    func didTapDelete(on cell: UserPostsCollectionViewCell)
}

class UserPostsCollectionViewCell: UICollectionViewCell {
    
    weak var delegate: UserPostsCellDelegate?
    
    //Closure Callbacksl) -> Void)?
    var onReadMoreTap: ((UserPostsCollectionViewCell) -> Void)?
    
    //Outlet connections
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userActionLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var optionsButton: UIButton!
    
    @IBOutlet weak var postTextLabel: UILabel!
    @IBOutlet weak var readMoreButton: UIButton!
    @IBOutlet weak var postImageView: UIImageView!
    
    @IBOutlet weak var referencedBookContainerView: UIView!
    @IBOutlet weak var referencedBookImageView: UIImageView!
    @IBOutlet weak var referencedBookHeaderLabel: UILabel!
    @IBOutlet weak var referencedBookTitleLabel: UILabel!
    @IBOutlet weak var referencedBookAuthorLabel: UILabel!
    
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var likeCountLabel: UILabel!
    @IBOutlet weak var commentButton: UIButton!
    @IBOutlet weak var commentCountLabel: UILabel!
    @IBOutlet weak var shareButton: UIButton!
    
    //separator view
    private let separatorView = UIView()
    private var isExpanded = false
    
    
    // Local state for fast UI toggles
    private var isLiked: Bool = false
    private var currentLikeCount: Int = 0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
        setupSeparator()
        setupActions()
        setupOptionsMenu()
        
        shareButton.isHidden = true // Hide standalone share button
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateReadMoreVisibility()
    }
    
    private func setupSeparator() {
        separatorView.backgroundColor = .systemGray5
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separatorView)
        
        NSLayoutConstraint.activate([
            separatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
    
    //Setup UIView, ImageView and No. of lines for post
    private func setupUI() {
        referencedBookContainerView.layer.cornerRadius = 12
        
        postImageView.layer.cornerRadius = 12
        postImageView.layer.masksToBounds = true
        
        profileImageView.layer.cornerRadius = 20
        profileImageView.layer.masksToBounds = true
        
        referencedBookImageView.layer.cornerRadius = 4
        referencedBookImageView.layer.masksToBounds = true
        
        postTextLabel.numberOfLines = 3
    }
    
    
    //Closure-based Actions
    private func setupActions() {
        commentButton.addAction(UIAction { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.didTapComment(on: self)
        }, for: .touchUpInside)
        
        likeButton.addAction(UIAction { [weak self] _ in
            guard let self = self else { return }
            self.isLiked.toggle()
            self.currentLikeCount += self.isLiked ? 1 : -1
            self.updateLikeButtonUI()
        }, for: .touchUpInside)
        
        readMoreButton.addAction(UIAction { [weak self] _ in
            guard let self = self else { return }
            self.isExpanded = true
            self.postTextLabel.numberOfLines = 0
            self.readMoreButton.isHidden = true
            self.onReadMoreTap?(self)
            
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }, for: .touchUpInside)
    }
    
    private func setupOptionsMenu() {
        let edit = UIAction(title: "Edit", image: UIImage(systemName: "pencil")) { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.didTapEdit(on: self)
        }
        let share = UIAction(title: "Share", image: UIImage(systemName: "square.and.arrow.up")) { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.didTapShare(on: self)
        }
        let delete = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.didTapDelete(on: self)
        }
        
        let menu = UIMenu(title: "", children: [edit, share, delete])
        optionsButton.menu = menu
        optionsButton.showsMenuAsPrimaryAction = true
    }
    
    
    //Text expands when clicked on 'Read More' button
    private func updateReadMoreVisibility() {
        guard let text = postTextLabel.text, !isExpanded else {
            readMoreButton.isHidden = true
            return
        }
        
        let size = CGSize(width: postTextLabel.frame.width, height: .greatestFiniteMagnitude)
        
        let fullHeight = text.boundingRect(
            with: size,
            options: .usesLineFragmentOrigin,
            attributes: [.font: postTextLabel.font!],
            context: nil
        ).height
        
        let maxHeight = postTextLabel.font.lineHeight * 3
        
        readMoreButton.isHidden = fullHeight <= maxHeight
    }
    
    
    //Configure cells
    func configure(with post: FeedPost) {
        isExpanded = false
        postTextLabel.numberOfLines = 3
        
        profileImageView.image = UIImage(named: "user_image2")
        userNameLabel.text = post.name
        userActionLabel.text = post.title
        timeLabel.text = post.time
        postTextLabel.text = post.content
        
        //Post Image
        if let postImage = post.postImage {
            postImageView.image = UIImage(named: postImage)
            postImageView.isHidden = false
        } else {
            postImageView.isHidden = true
            postImageView.image = nil
        }
        
        //Referenced book logic
        if let title = post.bookTitle {
            referencedBookContainerView.isHidden = false
            referencedBookTitleLabel.text = title
            referencedBookAuthorLabel.text = post.bookAuthor
            
            if let coverUrl = post.bookCoverImage {
                if coverUrl.hasPrefix("http") {
                    referencedBookImageView.loadFromUrl(coverUrl, placeholder: UIImage(systemName: "book"))
                } else {
                    referencedBookImageView.image = UIImage(named: coverUrl)
                }
            } else {
                referencedBookImageView.image = nil
            }
        } else if let bookId = post.bookId, let book = AppDependencies.shared.bookshelfData.bookMap[bookId] {
            // Fallback for older posts
            referencedBookContainerView.isHidden = false
            referencedBookTitleLabel.text = book.title
            referencedBookAuthorLabel.text = book.author
            referencedBookImageView.image = UIImage(named: book.coverImageURL)
        } else {
            referencedBookContainerView.isHidden = true
        }
        
        
        self.isLiked = post.isLiked
        self.currentLikeCount = post.likeCount
        
        commentCountLabel.text = "\(post.commentCount)"
        
        updateLikeButtonUI()
        updateReadMoreVisibility()
    }
    
    private func updateLikeButtonUI() {
        likeCountLabel.text = "\(currentLikeCount)"
        let heartImage = isLiked ? "heart.fill" : "heart"
        likeButton.setImage(UIImage(systemName: heartImage), for: .normal)
        likeButton.tintColor = isLiked ? .systemRed : .secondaryLabel
    }
}
