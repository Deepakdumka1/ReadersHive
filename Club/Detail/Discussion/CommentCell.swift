import UIKit

class CommentCell: UITableViewCell {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var avatarLabel: UILabel!
    @IBOutlet weak var usernameTimeLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var upvoteButton: UIButton!
    @IBOutlet weak var replyButton: UIButton!
    @IBOutlet weak var threadLineView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 16
        
        // Avatar setup
        avatarLabel.layer.cornerRadius = 12 // 24x24 assumed size
        avatarLabel.layer.masksToBounds = true
        avatarLabel.backgroundColor = .systemPurple
        avatarLabel.textColor = .white
        avatarLabel.textAlignment = .center
        avatarLabel.font = .boldSystemFont(ofSize: 12)
        
        // Actions
        upvoteButton.layer.cornerRadius = 12
        upvoteButton.backgroundColor = .systemGray6
        upvoteButton.tintColor = .secondaryLabel
        upvoteButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        upvoteButton.setTitleColor(.label, for: .normal)
        
        replyButton.tintColor = .secondaryLabel
        replyButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        replyButton.setTitleColor(.secondaryLabel, for: .normal)
        
        
        // Thread line
        threadLineView.backgroundColor = .systemGray4
        threadLineView.layer.cornerRadius = 1
    }

    func configure(with comment: Comment) {
        let displayName = comment.authorName ?? comment.userId
        avatarLabel.text = String(displayName.prefix(1)).uppercased()
        
        let attributedString = NSMutableAttributedString(string: "\(displayName)  ", attributes: [.font: UIFont.boldSystemFont(ofSize: 13), .foregroundColor: UIColor.label])
        attributedString.append(NSAttributedString(string: comment.createdAt ?? "", attributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.secondaryLabel]))
        usernameTimeLabel.attributedText = attributedString
        
        commentLabel.text = comment.content
        
        let upvoteIcon = UIImage(systemName: "heartBoo")
        upvoteButton.setImage(upvoteIcon, for: .normal)
        upvoteButton.setTitle(" \(comment.upvotes ?? 0)", for: .normal)
        
        let replyIcon = UIImage(systemName: "message")
        replyButton.setImage(replyIcon, for: .normal)
        replyButton.setTitle(" Reply", for: .normal)
        
    }
}
