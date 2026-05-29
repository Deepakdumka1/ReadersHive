//
//  MemberListTableViewCell.swift
//  Club
//
//  Created by Manas  on 23/03/26.
//

import UIKit
import FirebaseAuth

// Simple delegate to pass remove action back (same pattern as JoinDelegate)
protocol MemberRemoveDelegate: AnyObject {
    func didTapRemove(userId: String)
}

class MemberListTableViewCell: UITableViewCell {

    @IBOutlet weak var remove: UIButton!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var cellView: UIView!
    @IBOutlet weak var profileImage: UIImageView!

    weak var removeDelegate: MemberRemoveDelegate?
    private var memberId: String = ""
    private var isAdminMode: Bool = false

    override func awakeFromNib() {
        super.awakeFromNib()
        styleCell()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        profileImage.layer.cornerRadius = profileImage.bounds.height / 2
        remove.layer.cornerRadius = remove.bounds.height / 2
    }

    // MARK: - Styling

    private func styleCell() {
        selectionStyle = .none

        // Profile image — circular
        profileImage.clipsToBounds = true
        profileImage.contentMode = .scaleAspectFill
        profileImage.backgroundColor = UIColor.systemGray5

        // Name label — bold
        name.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        name.textColor = .label

        // Remove button — pill shape
        remove.clipsToBounds = true
        remove.configuration = nil
        remove.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)

        remove.addTarget(self, action: #selector(removeTapped), for: .touchUpInside)

        // Cell view
        cellView.backgroundColor = .clear
    }

    // MARK: - Configuration

    func configure(withProfile profile: Profile, isAdmin: Bool = false) {
        memberId = profile.userId
        name.text = profile.fullName
        isAdminMode = isAdmin

        let currentUserId = Auth.auth().currentUser?.uid
        if isAdmin && profile.userId != currentUserId {
            remove.isHidden = false
            remove.backgroundColor = .systemRed
            remove.setTitle("Remove", for: .normal)
            remove.setTitleColor(.white, for: .normal)
        } else {
            remove.isHidden = true
        }

        profileImage.image = nil
        let tag = 999
        profileImage.viewWithTag(tag)?.removeFromSuperview()

        if let avatarUrl = profile.avatarUrl, !avatarUrl.isEmpty {
            profileImage.loadFromUrl(avatarUrl)
        } else {
            profileImage.backgroundColor = colorForName(profile.fullName)
            let firstLetter = String(profile.fullName.prefix(1)).uppercased()
            let initialLabel = UILabel()
            initialLabel.tag = tag
            initialLabel.text = firstLetter
            initialLabel.textColor = .white
            initialLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
            initialLabel.textAlignment = .center
            initialLabel.translatesAutoresizingMaskIntoConstraints = false
            profileImage.addSubview(initialLabel)
            NSLayoutConstraint.activate([
                initialLabel.centerXAnchor.constraint(equalTo: profileImage.centerXAnchor),
                initialLabel.centerYAnchor.constraint(equalTo: profileImage.centerYAnchor)
            ])
        }
    }

    func configure(with memberName: String, isAdmin: Bool = false) {
        memberId = memberName
        name.text = memberName
        isAdminMode = isAdmin

        let currentUserId = Auth.auth().currentUser?.uid
        if isAdmin && memberName != currentUserId {
            // Admin sees a red "Remove" button for other members
            remove.isHidden = false
            remove.backgroundColor = .systemRed
            remove.setTitle("Remove", for: .normal)
            remove.setTitleColor(.white, for: .normal)
        } else {
            // Normal users and admin's own row don't see any button
            remove.isHidden = true
        }

        // Set a colored circle with the first letter as placeholder
        let firstLetter = String(memberName.prefix(1)).uppercased()
        profileImage.image = nil
        profileImage.backgroundColor = colorForName(memberName)

        // Add initial label if not already added
        let tag = 999
        if let existing = profileImage.viewWithTag(tag) as? UILabel {
            existing.text = firstLetter
        } else {
            let initialLabel = UILabel()
            initialLabel.tag = tag
            initialLabel.text = firstLetter
            initialLabel.textColor = .white
            initialLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
            initialLabel.textAlignment = .center
            initialLabel.translatesAutoresizingMaskIntoConstraints = false
            profileImage.addSubview(initialLabel)
            NSLayoutConstraint.activate([
                initialLabel.centerXAnchor.constraint(equalTo: profileImage.centerXAnchor),
                initialLabel.centerYAnchor.constraint(equalTo: profileImage.centerYAnchor)
            ])
        }
    }

    // MARK: - Remove Action

    @objc private func removeTapped() {
        removeDelegate?.didTapRemove(userId: memberId)
    }

    // MARK: - Helpers

    private func colorForName(_ name: String) -> UIColor {
        let colors: [UIColor] = [
            UIColor(red: 0.85, green: 0.35, blue: 0.35, alpha: 1.0),
            UIColor(red: 0.95, green: 0.65, blue: 0.30, alpha: 1.0),
            UIColor(red: 0.40, green: 0.70, blue: 0.55, alpha: 1.0),
            UIColor(red: 0.30, green: 0.50, blue: 0.80, alpha: 1.0),
            UIColor(red: 0.70, green: 0.40, blue: 0.70, alpha: 1.0),
            UIColor(red: 0.90, green: 0.45, blue: 0.55, alpha: 1.0),
        ]
        let index = abs(name.hashValue) % colors.count
        return colors[index]
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        remove.isHidden = true
        remove.backgroundColor = .systemRed
        remove.setTitle("Remove", for: .normal)
        remove.setTitleColor(.white, for: .normal)
        profileImage.image = nil
        profileImage.backgroundColor = .systemGray5
        let tag = 999
        profileImage.viewWithTag(tag)?.removeFromSuperview()
        removeDelegate = nil
    }
}
