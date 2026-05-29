//
//  ProfileSegmentHeaderView.swift
//  Club
//

import UIKit

protocol ProfileSegmentHeaderDelegate: AnyObject {
    func didChangeSegment(to index: Int)
}

class ProfileSegmentHeaderView: UICollectionReusableView {
    static let reuseIdentifier = "ProfileSegmentHeaderView"
    
    weak var delegate: ProfileSegmentHeaderDelegate?
    
    let segmentedControl: UISegmentedControl = {
        let items = ["Posts", "Clubs", "Shelf"]
        let sc = UISegmentedControl(items: items)
        sc.selectedSegmentIndex = 0
        sc.translatesAutoresizingMaskIntoConstraints = false
        
        // Force light mode so these colors don't flip and become mismatched
        sc.overrideUserInterfaceStyle = .light
        
        sc.selectedSegmentTintColor = .systemGray3
        sc.backgroundColor = .systemGray5
        
        let normalText = [NSAttributedString.Key.foregroundColor: UIColor.label]
        let selectedText = [NSAttributedString.Key.foregroundColor: UIColor.black]
        
        sc.setTitleTextAttributes(normalText, for: .normal)
        sc.setTitleTextAttributes(selectedText, for: .selected)
    
        return sc
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = .white
        addSubview(segmentedControl)
        
        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            segmentedControl.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            segmentedControl.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
        
        segmentedControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
    }
    
    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        delegate?.didChangeSegment(to: sender.selectedSegmentIndex)
    }
}
