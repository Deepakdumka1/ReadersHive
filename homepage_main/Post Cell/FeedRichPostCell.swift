import UIKit

protocol FeedRichPostCellDelegate: AnyObject {
    func didTapLike(on cell: FeedRichPostCell)
    func didTapShare(on cell: FeedRichPostCell)
    func didTapComment(on cell: FeedRichPostCell)
    func didTapUser(userId: String)
}

class FeedRichPostCell: UICollectionViewCell {
    var onBookTapped: (() -> Void)?
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
   // var onBookTapped: (() -> Void)?
    weak var delegate: FeedRichPostCellDelegate?
    
    private var userId: String?
    
    static let reuseIdentifier = "FeedRichPostCell"

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
        
        postImageView.isHidden = true
        bookRowView.isHidden = true
        addBottomSeparator()
        setupInteractions()
    }
    
    @objc private func userTapped() {
        guard let uid = userId else { return }
        delegate?.didTapUser(userId: uid)
    }
    
    @objc func bookTapped() {
        onBookTapped?()
    }
    func addBottomSeparator() {
        let separator = UIView()
        separator.backgroundColor = UIColor.systemGray4 // 🔥 darker line
        separator.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(separator)
        
        NSLayoutConstraint.activate([
            separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16), // nice padding
            separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale) // hairline
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

    func configureCell(with post: FeedPost, delegate: FeedRichPostCellDelegate?) {
        self.delegate = delegate
        self.userId = post.userId
        if let bookTitle = post.bookTitle {
            
            bookTitleLabel.text = bookTitle
     //   .text = post.bookAuthor
            
            if let cover = post.bookCoverImage {
                if cover.hasPrefix("http") {
                    bookCoverImageView.loadFromUrl(cover, placeholder: UIImage(systemName: "book"))
                } else {
                    bookCoverImageView.image = UIImage(named: cover)
                }
            }
            
            bookRowView.isHidden = false
            
        } else {
            
            // 🔥 RESET (IMPORTANT)
            bookTitleLabel.text = nil
      //      bookAuthorLabel.text = nil
            bookCoverImageView.image = nil
            bookRowView.isHidden = true
        }
        nameLabel.text = post.name
        timeLabel.text = post.time
        actionLabel.text = post.title
        contentLabel.text = post.content
        likeCountLabel.text = "\(post.likeCount)"
        commentCountLabel.text = "\(post.commentCount)"
        
        let liked = post.isLiked ?? false
        likeIconImageView.image = UIImage(systemName: liked ? "heart.fill" : "heart")
        likeIconImageView.tintColor = liked ? .systemRed : .black
        
        avatarImageView.loadFromUrl(post.avatarUrl)
    }
}
