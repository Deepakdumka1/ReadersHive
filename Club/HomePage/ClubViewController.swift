import UIKit
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

class ClubViewController: UIViewController {

    @IBOutlet var ClubCollectionView: UICollectionView!
    var clubdetailData: ClubDetailData!
    var clubData: ClubsData!
    var ClubsRecommended: [Club] = []
    var ClubsMy: [Club] = []
    var ClubsTrending: [Club] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Clubs"
        navigationController?.navigationBar.prefersLargeTitles = true

        registerCells()

        ClubCollectionView.register(
            UINib(nibName: "ClubSectionHeaderView", bundle: nil),
            forSupplementaryViewOfKind: "header",
            withReuseIdentifier: "header_view"
        )

        ClubCollectionView.setCollectionViewLayout(generateLayout(), animated: false)
        ClubCollectionView.dataSource = self
        ClubCollectionView.delegate = self
        ClubCollectionView.backgroundColor = .systemBackground
        
        // Fetch from Firebase
        clubData.fetchClubs { [weak self] in
            guard let self = self else { return }
            self.refreshClubDataAndUI()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshClubDataAndUI()
    }
    
    func refreshClubDataAndUI() {
        ClubsRecommended = clubData.clubs(for: .recommended)
        ClubsMy = clubData.clubs(for: .myClubs)
        ClubsTrending = clubData.clubs(for: .trending)
        ClubCollectionView.reloadData()
    }

    func registerCells() {
        ClubCollectionView.register(
            UINib(nibName: "ClubCollectionViewCell", bundle: nil),
            forCellWithReuseIdentifier: "ClubCollectionViewCell"
        )
    }

    @IBAction func CreateNewClub(_ sender: Any) {
        if Auth.auth().currentUser != nil {
            self.performSegue(withIdentifier: "CreateClub", sender: nil)
        } else {
            // User should already be logged in via SceneDelegate, but fallback if needed
            print("❌ User not logged in")
        }
    }
    
    @IBAction func unwindToClubViewController(_ unwindSegue: UIStoryboardSegue) {
        guard unwindSegue.identifier == "saveUnwind",
              let source = unwindSegue.source as? CreateClubTableViewController,
              let newClub = source.club else { return }

        // Save to Firebase
        clubData.saveClubToFirebase(newClub)
        refreshClubDataAndUI()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "homeToClubList",
           let vc = segue.destination as? MyClubsViewController,
           let section = sender as? Int {
            
            vc.clubdata = self.clubData
            vc.clubdetailData = self.clubdetailData
            
            switch section {
            case 0: vc.sectionType = .myClubs
            case 1: vc.sectionType = .recommended
            case 2: vc.sectionType = .trending
            default: break
            }
        }
    }
}

extension ClubViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let club: Club
        switch indexPath.section {
        case 0: club = ClubsMy[indexPath.item]
        case 1: club = ClubsRecommended[indexPath.item]
        case 2: club = ClubsTrending[indexPath.item]
        default: return
        }

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "KafkaViewController") as! KafkaViewController
        
        vc.clubId = club.id ?? ""
        vc.club = club
        vc.clubDetailData = clubdetailData
        vc.clubData = clubData
        vc.hidesBottomBarWhenPushed = true
        
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension ClubViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int { return 3 }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0: return ClubsMy.count
        case 1: return ClubsRecommended.count
        case 2: return ClubsTrending.count
        default: return 0
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ClubCollectionViewCell", for: indexPath) as! ClubCollectionViewCell
        let club: Club
        switch indexPath.section {
        case 0: club = ClubsMy[indexPath.item]
        case 1: club = ClubsRecommended[indexPath.item]
        case 2: club = ClubsTrending[indexPath.item]
        default: return UICollectionViewCell()
        }
        cell.configureCell(club: club)
        cell.delegate = self
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "header_view", for: indexPath) as! ClubSectionHeaderView
        switch indexPath.section {
        case 0: headerView.configure(with: "My Clubs", count: ClubsMy.count)
        case 1: headerView.configure(with: "Recommended")
        case 2: headerView.configure(with: "Trending")
        default: break
        }
        
        headerView.onHeaderButtonTapped = { [weak self] in
            self?.performSegue(withIdentifier: "homeToClubList", sender: indexPath.section)
        }
        return headerView
    }
}

extension ClubViewController {
    func generateLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { [weak self] (sectionIndex, _) -> NSCollectionLayoutSection? in
            guard let self = self else { return nil }
            let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(50)), elementKind: "header", alignment: .topLeading)
            
            if sectionIndex == 0 {
                let section = self.generateHorizontalSection()
                section.boundarySupplementaryItems = [header]
                return section
            } else {
                let section = self.generateGridSection()
                section.boundarySupplementaryItems = [header]
                return section
            }
        }
    }

    func generateHorizontalSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0)))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .absolute(211), heightDimension: .absolute(270)), repeatingSubitem: item, count: 1)
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 14
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 20, trailing: 16)
        section.orthogonalScrollingBehavior = .continuous
        return section
    }

    func generateGridSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0)))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .absolute(211), heightDimension: .absolute(270)), repeatingSubitem: item, count: 1)
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 14
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 20, trailing: 16)
        section.orthogonalScrollingBehavior = .continuous
        return section
    }
}

extension ClubViewController: JoinDelegate {
    func didTapJoin(clubId: String) {
        // Implementation for joining club in Firebase would go here
    }
}
