import UIKit

class BookshelfSectionHeaderView: UICollectionReusableView {

    @IBOutlet weak var titleButton: UIButton!
    @IBOutlet weak var chevronImageView: UIImageView!
    @IBOutlet weak var privacyImageView: UIImageView!
    var buttonAction: (() -> Void)?
    override func awakeFromNib() {
            super.awakeFromNib()

            chevronImageView.image = UIImage(systemName: "chevron.right")
            privacyImageView.tintColor = .systemGray

            titleButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        }

        @IBAction func titleTapped(_ sender: UIButton) {
            buttonAction?()
        }
    func configure(title: String, isPrivate: Bool) {
        titleButton.setTitle(title, for: .normal)
        titleButton.setTitleColor(.label, for: .normal)

        if isPrivate {
            privacyImageView.isHidden = false
            privacyImageView.image = UIImage(systemName: "lock.fill")
        } else {
            privacyImageView.isHidden = true
        }
    }
}
