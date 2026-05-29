import UIKit

class PostCell: UITableViewCell {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var profileLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
//    @IBOutlet weak var joinButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    // Stack and Actions
    @IBOutlet weak var upvoteButton: UIButton!
    @IBOutlet weak var commentButton: UIButton!


    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear // Transparent to let the table background show
        
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 16
        
        // Circular profile label
        profileLabel.layer.cornerRadius = 16 // 32x32 size assumed
        profileLabel.layer.masksToBounds = true
        profileLabel.backgroundColor = .systemOrange
        profileLabel.textColor = .white
        profileLabel.textAlignment = .center
        profileLabel.font = .boldSystemFont(ofSize: 16)
        
//        // Join club button
//        joinButton.layer.cornerRadius = 14
//        joinButton.backgroundColor = .systemBlue
//        joinButton.setTitleColor(.white, for: .normal)
//        joinButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .bold)
        
        // Setup action buttons styling
        let actionButtons = [upvoteButton, commentButton]
        for button in actionButtons {
            button?.layer.cornerRadius = 16
            button?.backgroundColor = .systemGray6
            button?.tintColor = .secondaryLabel
            button?.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
            button?.setTitleColor(.label, for: .normal)
        }
    }

    func configure(with post: DiscussionPost) {
        profileLabel.text = String(post.authorName.prefix(1)).uppercased()
        usernameLabel.text = post.authorName
        timeLabel.text = post.createdAt
        titleLabel.text = post.title
        descriptionLabel.text = post.content
        
        let upvoteIcon = UIImage(systemName: "heart")
        upvoteButton.setImage(upvoteIcon, for: .normal)
        upvoteButton.setTitle(" \(post.upvotes ?? 0)", for: .normal)
        
        let commentIcon = UIImage(systemName: "message")
        commentButton.setImage(commentIcon, for: .normal)
        commentButton.setTitle(" \(post.commentCount ?? 0)", for: .normal)
        
//        let shareIcon = UIImage(systemName: "square.and.arrow.up")
//        shareButton.setImage(shareIcon, for: .normal)
//        shareButton.setTitle(" Share", for: .normal)
    }
}
