import UIKit

protocol PostHeaderViewDelegate: AnyObject {
    func didTapLike(on headerView: PostHeaderView)
}

class PostHeaderView: UIView {
    
    weak var delegate: PostHeaderViewDelegate?
    
    let avatarImageView = UIImageView()
    let nameLabel = UILabel()
    let timeLabel = UILabel()
    
    let contentLabel = UILabel()
    let postImageView = UIImageView()
    
    let bookContainerView = UIView()
    let bookCoverImageView = UIImageView()
    let bookTitleLabel = UILabel()
    let bookAuthorLabel = UILabel()
    
    let likeIcon = UIImageView()
    let likeLabel = UILabel()
    let commentIcon = UIImageView()
    let commentLabel = UILabel()
    let separator = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .systemBackground
        
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.layer.cornerRadius = 20
        avatarImageView.clipsToBounds = true
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.backgroundColor = .systemGray5
        addSubview(avatarImageView)
        
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .boldSystemFont(ofSize: 16)
        addSubview(nameLabel)
        
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.font = .systemFont(ofSize: 12)
        timeLabel.textColor = .secondaryLabel
        addSubview(timeLabel)
        
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        contentLabel.font = .systemFont(ofSize: 15)
        contentLabel.numberOfLines = 0
        addSubview(contentLabel)
        
        postImageView.translatesAutoresizingMaskIntoConstraints = false
        postImageView.contentMode = .scaleAspectFill
        postImageView.layer.cornerRadius = 12
        postImageView.clipsToBounds = true
        addSubview(postImageView)
        
        bookContainerView.translatesAutoresizingMaskIntoConstraints = false
        bookContainerView.backgroundColor = .systemGray6
        bookContainerView.layer.cornerRadius = 8
        addSubview(bookContainerView)
        
        bookCoverImageView.translatesAutoresizingMaskIntoConstraints = false
        bookCoverImageView.contentMode = .scaleAspectFill
        bookCoverImageView.layer.cornerRadius = 4
        bookCoverImageView.clipsToBounds = true
        bookContainerView.addSubview(bookCoverImageView)
        
        bookTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        bookTitleLabel.font = .boldSystemFont(ofSize: 14)
        bookContainerView.addSubview(bookTitleLabel)
        
        bookAuthorLabel.translatesAutoresizingMaskIntoConstraints = false
        bookAuthorLabel.font = .systemFont(ofSize: 12)
        bookAuthorLabel.textColor = .secondaryLabel
        bookContainerView.addSubview(bookAuthorLabel)
        
        likeIcon.translatesAutoresizingMaskIntoConstraints = false
        likeIcon.image = UIImage(systemName: "heart")
        likeIcon.tintColor = .secondaryLabel
        addSubview(likeIcon)
        
        likeLabel.translatesAutoresizingMaskIntoConstraints = false
        likeLabel.font = .systemFont(ofSize: 14)
        likeLabel.textColor = .secondaryLabel
        addSubview(likeLabel)
        
        commentIcon.translatesAutoresizingMaskIntoConstraints = false
        commentIcon.image = UIImage(systemName: "message")
        commentIcon.tintColor = .secondaryLabel
        addSubview(commentIcon)
        
        commentLabel.translatesAutoresizingMaskIntoConstraints = false
        commentLabel.font = .systemFont(ofSize: 14)
        commentLabel.textColor = .secondaryLabel
        addSubview(commentLabel)
        
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.backgroundColor = .systemGray4
        addSubview(separator)
        
        NSLayoutConstraint.activate([
            avatarImageView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            avatarImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            avatarImageView.widthAnchor.constraint(equalToConstant: 40),
            avatarImageView.heightAnchor.constraint(equalToConstant: 40),
            
            nameLabel.topAnchor.constraint(equalTo: avatarImageView.topAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            timeLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            timeLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            timeLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            
            contentLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 12),
            contentLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            contentLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            postImageView.topAnchor.constraint(equalTo: contentLabel.bottomAnchor, constant: 12),
            postImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            postImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            bookContainerView.topAnchor.constraint(equalTo: postImageView.bottomAnchor, constant: 12),
            bookContainerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            bookContainerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            bookContainerView.heightAnchor.constraint(equalToConstant: 60),
            
            bookCoverImageView.leadingAnchor.constraint(equalTo: bookContainerView.leadingAnchor, constant: 8),
            bookCoverImageView.centerYAnchor.constraint(equalTo: bookContainerView.centerYAnchor),
            bookCoverImageView.widthAnchor.constraint(equalToConstant: 35),
            bookCoverImageView.heightAnchor.constraint(equalToConstant: 50),
            
            bookTitleLabel.topAnchor.constraint(equalTo: bookContainerView.topAnchor, constant: 10),
            bookTitleLabel.leadingAnchor.constraint(equalTo: bookCoverImageView.trailingAnchor, constant: 12),
            bookTitleLabel.trailingAnchor.constraint(equalTo: bookContainerView.trailingAnchor, constant: -8),
            
            bookAuthorLabel.topAnchor.constraint(equalTo: bookTitleLabel.bottomAnchor, constant: 2),
            bookAuthorLabel.leadingAnchor.constraint(equalTo: bookTitleLabel.leadingAnchor),
            bookAuthorLabel.trailingAnchor.constraint(equalTo: bookTitleLabel.trailingAnchor),
            
            likeIcon.topAnchor.constraint(equalTo: bookContainerView.bottomAnchor, constant: 16),
            likeIcon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            likeIcon.widthAnchor.constraint(equalToConstant: 20),
            likeIcon.heightAnchor.constraint(equalToConstant: 20),
            
            likeLabel.centerYAnchor.constraint(equalTo: likeIcon.centerYAnchor),
            likeLabel.leadingAnchor.constraint(equalTo: likeIcon.trailingAnchor, constant: 6),
            
            commentIcon.centerYAnchor.constraint(equalTo: likeIcon.centerYAnchor),
            commentIcon.leadingAnchor.constraint(equalTo: likeLabel.trailingAnchor, constant: 16),
            commentIcon.widthAnchor.constraint(equalToConstant: 20),
            commentIcon.heightAnchor.constraint(equalToConstant: 20),
            
            commentLabel.centerYAnchor.constraint(equalTo: commentIcon.centerYAnchor),
            commentLabel.leadingAnchor.constraint(equalTo: commentIcon.trailingAnchor, constant: 6),
            
            separator.topAnchor.constraint(equalTo: likeIcon.bottomAnchor, constant: 16),
            separator.leadingAnchor.constraint(equalTo: leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1),
            separator.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        let likeTap = UITapGestureRecognizer(target: self, action: #selector(likeTapped))
        likeIcon.isUserInteractionEnabled = true
        likeIcon.addGestureRecognizer(likeTap)
        
        let likeLabelTap = UITapGestureRecognizer(target: self, action: #selector(likeTapped))
        likeLabel.isUserInteractionEnabled = true
        likeLabel.addGestureRecognizer(likeLabelTap)
    }
    
    @objc private func likeTapped() {
        delegate?.didTapLike(on: self)
    }
    
    func configure(with post: FeedPost) {
        nameLabel.text = post.name
        timeLabel.text = post.time
        contentLabel.text = post.content
        
        avatarImageView.loadFromUrl(post.avatarUrl, placeholder: UIImage(systemName: "person.circle.fill"))
        
        // Dynamic Heights
        let hasPostImage = post.postImage != nil
        let hasBook = post.bookTitle != nil
        
        if hasPostImage {
            postImageView.isHidden = false
            postImageView.loadFromUrl(post.postImage, placeholder: nil)
            
            postImageView.constraints.first { $0.firstAttribute == .height }?.isActive = false
            let heightConstraint = postImageView.heightAnchor.constraint(equalToConstant: 200)
            heightConstraint.priority = .defaultHigh
            heightConstraint.isActive = true
        } else {
            postImageView.isHidden = true
            postImageView.image = nil
            postImageView.constraints.first { $0.firstAttribute == .height }?.isActive = false
            let heightConstraint = postImageView.heightAnchor.constraint(equalToConstant: 0)
            heightConstraint.priority = .defaultHigh
            heightConstraint.isActive = true
        }
        
        if hasBook {
            bookContainerView.isHidden = false
            bookTitleLabel.text = post.bookTitle
            bookAuthorLabel.text = post.bookAuthor
            
            if let coverUrl = post.bookCoverImage {
                if coverUrl.hasPrefix("http") {
                    bookCoverImageView.loadFromUrl(coverUrl, placeholder: UIImage(systemName: "book"))
                } else {
                    bookCoverImageView.image = UIImage(named: coverUrl)
                }
            } else {
                bookCoverImageView.image = nil
            }
            
            bookContainerView.constraints.first { $0.firstAttribute == .height }?.isActive = false
            let heightConstraint = bookContainerView.heightAnchor.constraint(equalToConstant: 60)
            heightConstraint.priority = .defaultHigh
            heightConstraint.isActive = true
            
        } else {
            bookContainerView.isHidden = true
            bookContainerView.constraints.first { $0.firstAttribute == .height }?.isActive = false
            let heightConstraint = bookContainerView.heightAnchor.constraint(equalToConstant: 0)
            heightConstraint.priority = .defaultHigh
            heightConstraint.isActive = true
        }
        
        likeLabel.text = "\(post.likeCount)"
        commentLabel.text = "\(post.commentCount)"
        
        if post.isLiked {
            likeIcon.image = UIImage(systemName: "heart.fill")
            likeIcon.tintColor = .systemRed
        } else {
            likeIcon.image = UIImage(systemName: "heart")
            likeIcon.tintColor = .secondaryLabel
        }
    }
}
