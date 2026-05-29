import UIKit

protocol FeedRichPostCellWithImageDelegate: AnyObject {
    func didTapLike(on cell: FeedRichPostCellWithImage)
    func didTapShare(on cell: FeedRichPostCellWithImage)
    func didTapComment(on cell: FeedRichPostCellWithImage)
    func didTapUser(userId: String)
}

class FeedRichPostCellWithImage: UICollectionViewCell {
    
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var actionLabel: UILabel!
    
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var postImageView: UIImageView!
    
    @IBOutlet weak var bookRowView: UIView!
    @IBOutlet weak var bookTitleLabel: UILabel!
    @IBOutlet weak var bookCoverImageView: UIImageView!
    
    @IBOutlet weak var likeCountLabel: UILabel!
    @IBOutlet weak var commentCountLabel: UILabel!
    
    @IBOutlet weak var likeStackView: UIStackView!
    @IBOutlet weak var likeIconImageView: UIImageView!
    @IBOutlet weak var shareIconImageView: UIImageView!
    
    weak var delegate: FeedRichPostCellWithImageDelegate?
    var onBookTapped: (() -> Void)?
    private var userId: String?

    @objc func bookTapped() {
        onBookTapped?()
    }
    static let reuseIdentifier = "FeedRichPostCellWithImage"
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let tap = UITapGestureRecognizer(target: self, action: #selector(bookTapped))
        bookRowView.addGestureRecognizer(tap)
        bookRowView.isUserInteractionEnabled = true
        
        avatarImageView.layer.cornerRadius = 20
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.borderWidth = 1.5
        avatarImageView.layer.borderColor = UIColor.systemGray6.cgColor
        avatarImageView.isUserInteractionEnabled = true
        let avatarTap = UITapGestureRecognizer(target: self, action: #selector(userTapped))
        avatarImageView.addGestureRecognizer(avatarTap)
        
        nameLabel.isUserInteractionEnabled = true
        let nameTap = UITapGestureRecognizer(target: self, action: #selector(userTapped))
        nameLabel.addGestureRecognizer(nameTap)
        
        postImageView.isHidden = false
        bookRowView.isHidden = false
        postImageView.layer.cornerRadius = 16
        postImageView.clipsToBounds = true
        
        bookCoverImageView.layer.cornerRadius = 8
        bookCoverImageView.clipsToBounds = true
        addBottomSeparator()
        setupInteractions()
    }
    
    @objc private func userTapped() {
        guard let uid = userId else { return }
        delegate?.didTapUser(userId: uid)
    }
    
    func addBottomSeparator() {
        let separator = UIView()
        separator.backgroundColor = UIColor.systemGray4  // darker line
        separator.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(separator)
        
        NSLayoutConstraint.activate([
            separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16), // nice padding
            separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.5) // hairline
        ])
    }
    private func setupInteractions() {
        likeStackView.isUserInteractionEnabled = true
        let likeTap = UITapGestureRecognizer(target: self, action: #selector(handleLikeTap))
        likeStackView.addGestureRecognizer(likeTap)
        
        shareIconImageView.isUserInteractionEnabled = true
        let shareTap = UITapGestureRecognizer(target: self, action: #selector(handleShareTap))
        shareIconImageView.addGestureRecognizer(shareTap)
        
        commentCountLabel.isUserInteractionEnabled = true
        let commentTap = UITapGestureRecognizer(target: self, action: #selector(handleCommentTap))
        commentCountLabel.addGestureRecognizer(commentTap)
        if let commentStack = commentCountLabel.superview {
            commentStack.isUserInteractionEnabled = true
            commentStack.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleCommentTap)))
        }
    }
    
    @objc private func handleLikeTap() {
        delegate?.didTapLike(on: self)
    }
    
    @objc private func handleShareTap() {
        delegate?.didTapShare(on: self)
    }
    
    @objc private func handleCommentTap() {
        delegate?.didTapComment(on: self)
    }
    
    func configureCell(with post: FeedPost, delegate: FeedRichPostCellWithImageDelegate?) {
        // Book handling
        if let bookTitle = post.bookTitle {
            bookTitleLabel.text = bookTitle
            
            if let coverImage = post.bookCoverImage {
                bookCoverImageView.loadFromUrl(coverImage, placeholder: UIImage(systemName: "book"))
            }
            
            bookRowView.isHidden = false
        } else {
            bookTitleLabel.text = nil
            bookCoverImageView.image = nil
            bookRowView.isHidden = true
        }
        self.delegate = delegate
        self.userId = post.userId
        nameLabel.text = post.name
        timeLabel.text = post.time
        actionLabel.text = post.title
        contentLabel.text = post.content
        likeCountLabel.text = "\(post.likeCount)"
        commentCountLabel.text = "\(post.commentCount)"
        
        let heartImage = post.isLiked ? "heart.fill" : "heart"
        likeIconImageView.image = UIImage(systemName: heartImage)
        likeIconImageView.tintColor = post.isLiked ? .systemRed : .secondaryLabel
        
        // 🔥 LOAD AVATAR FROM URL
        avatarImageView.loadFromUrl(post.avatarUrl)
        
        // Post image handling
        if let localImage = post.localImage {
            postImageView.image = localImage
            postImageView.isHidden = false
        } else if let postImageUrl = post.postImage {
            postImageView.loadFromUrl(postImageUrl, placeholder: nil)
            postImageView.isHidden = false
        } else {
            postImageView.isHidden = true
        }
    }
}
