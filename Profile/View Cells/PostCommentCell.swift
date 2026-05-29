import UIKit

class PostCommentCell: UITableViewCell {
    
    static let identifier = "PostCommentCell"
    
    let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .systemGray5
        iv.layer.cornerRadius = 20 // 40x40 size
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    let bubbleView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 14)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let commentLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15)
        label.textColor = .label
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(avatarImageView)
        contentView.addSubview(bubbleView)
        bubbleView.addSubview(nameLabel)
        bubbleView.addSubview(commentLabel)
        
        NSLayoutConstraint.activate([
            avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatarImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            avatarImageView.widthAnchor.constraint(equalToConstant: 40),
            avatarImageView.heightAnchor.constraint(equalToConstant: 40),
            
            bubbleView.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            bubbleView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            nameLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 8),
            nameLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
            
            commentLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            commentLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            commentLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
            commentLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -10)
        ])
    }
    
    func configure(with comment: PostComment) {
        nameLabel.text = comment.userName
        commentLabel.text = comment.content
        
        if let urlStr = comment.userAvatarUrl, !urlStr.isEmpty {
            if urlStr.hasPrefix("http") {
                avatarImageView.loadFromUrl(urlStr)
            } else if let img = UIImage(named: urlStr) {
                avatarImageView.image = img
            } else {
                avatarImageView.image = UIImage(systemName: "person.circle.fill")
                avatarImageView.tintColor = .systemGray
            }
        } else {
            avatarImageView.image = UIImage(systemName: "person.circle.fill")
            avatarImageView.tintColor = .systemGray
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        avatarImageView.image = nil
    }
}
