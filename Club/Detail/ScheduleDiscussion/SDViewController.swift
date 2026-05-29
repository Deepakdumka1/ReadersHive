//
//  SDViewController.swift
//  Club
//
//  Created by Manas  on 05/04/26.
//

import UIKit
import FirebaseFirestore

class SDViewController: UIViewController {
    
    @IBOutlet var SDCollectionView: UICollectionView!
    
    var discussion: Discussion!
    var clubDetailData: ClubDetailData!
    var isMember: Bool = false
    var hostProfile: Profile?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // For ignoring safe area on top (same as KafkaViewController)
        navigationController?.navigationBar.isTranslucent = true
        SDCollectionView.contentInsetAdjustmentBehavior = .never
        
        SDCollectionView.dataSource = self
        
        // Register all SD XIB cells
        SDCollectionView.register(
            UINib(nibName: "SDHeaderCollectionViewCell", bundle: nil),
            forCellWithReuseIdentifier: "sd_header_cell"
        )
        SDCollectionView.register(
            UINib(nibName: "SDJoinButtonCollectionViewCell", bundle: nil),
            forCellWithReuseIdentifier: "SDjoin_cell"
        )
        SDCollectionView.register(
            UINib(nibName: "SDDiscussionDetailCollectionViewCell", bundle: nil),
            forCellWithReuseIdentifier: "sd_detail_cell"
        )
        SDCollectionView.register(
            UINib(nibName: "SDDescriptionCollectionViewCell", bundle: nil),
            forCellWithReuseIdentifier: "sd_description_cell"
        )
        SDCollectionView.register(
            UINib(nibName: "SDMeetingLinkCollectionViewCell", bundle: nil),
            forCellWithReuseIdentifier: "sd_meeting_cell"
        )
        
        // Register section header
        SDCollectionView.register(
            UINib(nibName: "SDSectionHeaderCollectionViewCell", bundle: nil),
            forSupplementaryViewOfKind: "sd_header",
            withReuseIdentifier: "sd_header_view"
        )
        
        let layout = generateLayout()
        SDCollectionView.setCollectionViewLayout(layout, animated: true)
        
        fetchHostProfile()
    }
    
    private func fetchHostProfile() {
        let hostId = discussion.createdBy
        Firestore.firestore().collection("profiles").document(hostId).getDocument { [weak self] snapshot, error in
            if let data = try? snapshot?.data(as: Profile.self) {
                self?.hostProfile = data
                DispatchQueue.main.async {
                    self?.SDCollectionView.reloadSections(IndexSet(integer: 2))
                }
            }
        }
    }
}

// MARK: - UICollectionViewDataSource
extension SDViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 5
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0: return 1  // SD Header
        case 1: return 1  // SD Join Button
        case 2: return 1  // Discussion Details (DATE, TIME, HOST)
        case 3: return 1  // About the discussion (Description)
        case 4: return 1  // Meeting link
        default: return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {
        case 0:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "sd_header_cell",
                for: indexPath
            ) as! SDHeaderCollectionViewCell
            cell.configure(with: discussion)
            return cell
        case 1:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "SDjoin_cell",
                for: indexPath
            ) as! SDJoinButtonCollectionViewCell
            cell.configure(discussion: discussion)
            return cell
        case 2:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "sd_detail_cell",
                for: indexPath
            ) as! SDDiscussionDetailCollectionViewCell
            cell.configure(with: discussion, hostName: hostProfile?.fullName)
            cell.onHostTapped = { [weak self] in
                guard let profile = self?.hostProfile else { return }
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                if let vc = storyboard.instantiateViewController(withIdentifier: "OtherUserProfileViewController") as? OtherUserProfileViewController {
                    vc.profile = profile
                    self?.navigationController?.pushViewController(vc, animated: true)
                }
            }
            return cell
        case 3:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "sd_description_cell",
                for: indexPath
            ) as! SDDescriptionCollectionViewCell
            cell.configure(with: discussion)
            return cell
        case 4:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "sd_meeting_cell",
                for: indexPath
            ) as! SDMeetingLinkCollectionViewCell
            cell.configure(with: discussion)
            let currentDiscussion = discussion

            cell.onLaunchTapped = {
                guard let link = currentDiscussion?.meetingLink else { return }
                var finalLink = link
                if !finalLink.lowercased().hasPrefix("http://") && !finalLink.lowercased().hasPrefix("https://") {
                    finalLink = "https://" + finalLink
                }
                if let url = URL(string: finalLink) {
                    UIApplication.shared.open(url)
                }
            }
            return cell
        default:
            return UICollectionViewCell()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        var headerView: SDSectionHeaderCollectionViewCell!
        
        if kind == "sd_header" {
            headerView = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: "sd_header_view",
                for: indexPath
            ) as? SDSectionHeaderCollectionViewCell
            
            if indexPath.section == 2 {
                headerView.configure(withTitle: "Discussion details")
            } else if indexPath.section == 3 {
                headerView.configure(withTitle: "About the discussion")
            } else if indexPath.section == 4 {
                headerView.configure(withTitle: "Meeting link")
            }
        }
        return headerView
    }
}

// MARK: - Compositional Layout
extension SDViewController {
    
    func generateLayout() -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout { [weak self] sectionIndex, environment -> NSCollectionLayoutSection? in
            guard let self = self else { return nil }
            
            let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(50))
            let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: "sd_header", alignment: .topLeading)
            
            switch sectionIndex {
            case 0:
                return self.generateHeaderLayout()
            case 1:
                return self.generateJoinButtonLayout()
            case 2:
                let section = self.generateDetailLayout()
                section.boundarySupplementaryItems = [header]
                return section
            case 3:
                let section = self.generateDescriptionLayout()
                section.boundarySupplementaryItems = [header]
                return section
            case 4:
                let section = self.generateMeetingLinkLayout()
                section.boundarySupplementaryItems = [header]
                return section
            default:
                return self.generateDetailLayout()
            }
        }
        return layout
    }
    
    func generateHeaderLayout() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(200))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, repeatingSubitem: item, count: 1)
        
        let section = NSCollectionLayoutSection(group: group)
        return section
    }
    
    func generateJoinButtonLayout() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(80))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, repeatingSubitem: item, count: 1)
        
        let section = NSCollectionLayoutSection(group: group)
        return section
    }
    
    func generateDetailLayout() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(100))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, repeatingSubitem: item, count: 1)
        
        let section = NSCollectionLayoutSection(group: group)
        return section
    }
    
    func generateDescriptionLayout() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(150))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, repeatingSubitem: item, count: 1)
        
        let section = NSCollectionLayoutSection(group: group)
        return section
    }
    
    func generateMeetingLinkLayout() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(100))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, repeatingSubitem: item, count: 1)
        
        let section = NSCollectionLayoutSection(group: group)
        return section
    }
}
