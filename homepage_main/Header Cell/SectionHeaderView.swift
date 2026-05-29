import UIKit

class SectionHeaderView: UICollectionReusableView {
    
    @IBOutlet weak var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func configure(withTitle title: String) {
        titleLabel.text = title
    }
}
