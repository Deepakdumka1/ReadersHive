//
//  BookFilterChipCell.swift
//  Club
//
//  Created by Antigravity on 28/04/26.
//
//  Programmatic UICollectionViewCell for horizontally scrollable filter chips
//  in the Community tab. Pill-shaped, highlights when selected.
//

import UIKit

class BookFilterChipCell: UICollectionViewCell {
    
    static let reuseId = "BookFilterChipCell"
    
    // MARK: - UI Elements
    
    private let pillContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.cornerRadius = 16
        v.layer.borderWidth = 1.5
        v.layer.borderColor = UIColor(red: 0.85, green: 0.85, blue: 0.88, alpha: 1.0).cgColor
        v.backgroundColor = .white
        return v
    }()
    
    private let pillLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 14, weight: .medium)
        l.textColor = UIColor(red: 0.35, green: 0.35, blue: 0.45, alpha: 1.0)
        l.textAlignment = .center
        return l
    }()
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        
        contentView.addSubview(pillContainer)
        pillContainer.addSubview(pillLabel)
        
        NSLayoutConstraint.activate([
            pillContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            pillContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            pillContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            pillContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            pillLabel.topAnchor.constraint(equalTo: pillContainer.topAnchor, constant: 6),
            pillLabel.bottomAnchor.constraint(equalTo: pillContainer.bottomAnchor, constant: -6),
            pillLabel.leadingAnchor.constraint(equalTo: pillContainer.leadingAnchor, constant: 16),
            pillLabel.trailingAnchor.constraint(equalTo: pillContainer.trailingAnchor, constant: -16),
        ])
    }
    
    // MARK: - Configure
    
    /// Configure the chip with a tag, selection state, and dynamic theme color.
    func configure(with tag: BookDiscussionTag, isSelected: Bool, themeColor: UIColor? = nil) {
        pillLabel.text = tag.rawValue
        
        if isSelected {
            // Use custom theme color if available, otherwise default purple
            let activeColor = themeColor ?? UIColor(red: 0.482, green: 0.380, blue: 0.961, alpha: 1.0)
            pillContainer.backgroundColor = activeColor
            pillContainer.layer.borderColor = UIColor.clear.cgColor
            pillLabel.textColor = .white
        } else {
            // Border-only state
            pillContainer.backgroundColor = .white
            pillContainer.layer.borderColor = UIColor(red: 0.85, green: 0.85, blue: 0.88, alpha: 1.0).cgColor
            pillLabel.textColor = UIColor(red: 0.35, green: 0.35, blue: 0.45, alpha: 1.0)
        }
    }
}
