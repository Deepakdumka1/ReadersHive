import UIKit

protocol SuggestedUserCellDelegate: AnyObject {
    func didTapFollow(userId: String)
    func didTapClose(userId: String)
    func didTapUser(userId: String)
}

class SuggestedUserCell: UICollectionViewCell {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var followButton: UIButton!
    
    weak var delegate: SuggestedUserCellDelegate?
    private var memberId: String = ""
    static let reuseIdentifier = "SuggestedUserCell"
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        containerView.layer.cornerRadius = 16
        
        avatarImageView.layer.cornerRadius = 35
        avatarImageView.clipsToBounds = true
        
        followButton.layer.cornerRadius = 16
        followButton.clipsToBounds = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(containerTapped))
        containerView.addGestureRecognizer(tap)
        containerView.isUserInteractionEnabled = true
    }
    
    @objc private func containerTapped() {
        delegate?.didTapUser(userId: memberId)
    }
    
    @IBAction func followTapped(_ sender: UIButton) {
        delegate?.didTapFollow(userId: memberId) // Using memberId which is the userId
    }
    
    @IBAction func closeTapped(_ sender: UIButton) {
        delegate?.didTapClose(userId: memberId)
    }
    
    func configureCell(with user: SuggestedUser, delegate: SuggestedUserCellDelegate?) {
        self.delegate = delegate
        self.memberId = user.id
        usernameLabel.text = user.username
        nameLabel.text = user.name
        
        // Use the new centralized loading system
        avatarImageView.loadFromUrl(user.avatarImage)
        
        if user.isFollowing {
            followButton.setTitle("Following", for: .normal)
            followButton.backgroundColor = .systemGray4
            followButton.setTitleColor(.black, for: .normal)
        } else {
            followButton.setTitle("Follow", for: .normal)
            followButton.backgroundColor = .systemBlue
            followButton.setTitleColor(.white, for: .normal)
        }
    }
}
