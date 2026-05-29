import UIKit
import FirebaseFirestore
import FirebaseAuth

class searchViewController: UIViewController {
    
    @IBOutlet weak var segmentControl: UISegmentedControl!
    @IBOutlet weak var mainsearchCollectionView: UICollectionView!
    
    let searchController = UISearchController(searchResultsController: nil)
    
    enum SearchType {
        case users
        case books
        case clubs
    }
    
    var currentType: SearchType = .books
    var profileData: ProfileData!
    var search_book: BookshelfData!
    var clubData: ClubsData!
    var clubDetailData: ClubDetailData!
    
    var users: [Profile] = []
    var recentUsers: [Profile] = []
    var allBooks: [Book] = []
    var clubs: [Club] = []
    
    var filteredUsers: [Profile] = []
    var filteredBooks: [Book] = []
    var filteredClubs: [Club] = []
    
    var suggestedBooks: [Book] = []
    var newReleases: [Book] = []
    var trendingBooks: [Book] = []
    
    var suggestedClubs: [Club] = []
    var trendingClubs: [Club] = []
    var newClubs: [Club] = []
    
    var googleBooks: [GoogleBook] = []
    
    private var clubListener: ListenerRegistration?
    private var profileListener: ListenerRegistration?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupSearchController()
        loadData()
    }
    
    private func setupUI() {
        title = "Search"
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.largeTitleDisplayMode = .never
        
        mainsearchCollectionView.delegate = self
        mainsearchCollectionView.dataSource = self
        mainsearchCollectionView.collectionViewLayout = generateLayout()
        
        // Register Cells
        mainsearchCollectionView.register(UINib(nibName: "BooksCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "BooksCollectionViewCell")
        mainsearchCollectionView.register(UINib(nibName: "UserCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "UserCollectionViewCell")
        mainsearchCollectionView.register(UINib(nibName: "ClubCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "ClubCollectionViewCell")
        mainsearchCollectionView.register(UINib(nibName: "searchheader", bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "searchheader")
        
        segmentControl.selectedSegmentIndex = 1
        currentType = .books
    }
    
    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Books, Clubs, Users"
        searchController.hidesNavigationBarDuringPresentation = false
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }
    
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0: currentType = .users
        case 1: currentType = .books
        case 2: currentType = .clubs
        default: break
        }
        
        searchController.searchBar.text = ""
        searchController.isActive = false
        
        filteredUsers = recentUsers
        filteredBooks = allBooks
        filteredClubs = clubs
        
        mainsearchCollectionView.setCollectionViewLayout(generateLayout(), animated: false)
        mainsearchCollectionView.reloadData()
    }
    
    func loadData() {
        let db = Firestore.firestore()
        
        // 1. Books
        allBooks = search_book.allBooks
        suggestedBooks = allBooks
        newReleases = allBooks
        trendingBooks = allBooks
        filteredBooks = allBooks
        
        // 2. Clubs Sync
        clubListener?.remove()
        clubListener = db.collection("clubs").addSnapshotListener { [weak self] snapshot, _ in
            guard let self = self else { return }
            let fetchedClubs = snapshot?.documents.compactMap { try? $0.data(as: Club.self) } ?? []
            self.clubs = fetchedClubs
            self.suggestedClubs = Array(fetchedClubs.prefix(4))
            self.trendingClubs = Array(fetchedClubs.dropFirst(4).prefix(4))
            self.newClubs = Array(fetchedClubs.dropFirst(8).prefix(4))
            
            if self.currentType == .clubs && (self.searchController.searchBar.text?.isEmpty ?? true) {
                self.filteredClubs = fetchedClubs
                self.mainsearchCollectionView.reloadData()
            }
        }
        
        // 3. Users Sync
        profileListener?.remove()
        profileListener = db.collection("profiles").addSnapshotListener { [weak self] snapshot, _ in
            guard let self = self else { return }
            let fetchedUsers = snapshot?.documents.compactMap { try? $0.data(as: Profile.self) } ?? []
            self.users = fetchedUsers
            
            if self.currentType == .users && (self.searchController.searchBar.text?.isEmpty ?? true) {
                self.filteredUsers = self.recentUsers.isEmpty ? Array(fetchedUsers.prefix(10)) : self.recentUsers
                self.mainsearchCollectionView.reloadData()
            }
        }
    }
}

// MARK: - UISearchResultsUpdating
extension searchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let text = searchController.searchBar.text ?? ""
        let query = text.lowercased()
        
        if query.isEmpty {
            filteredUsers = recentUsers
            filteredBooks = allBooks
            filteredClubs = clubs
            mainsearchCollectionView.reloadData()
            return
        }
        
        switch currentType {
        case .users:
            filteredUsers = users.filter {
                $0.fullName.lowercased().contains(query) ||
                $0.username.lowercased().contains(query) ||
                ($0.bio?.lowercased().contains(query) ?? false)
            }
            mainsearchCollectionView.reloadData()
            
        case .clubs:
            filteredClubs = clubs.filter {
                ($0.name?.lowercased().contains(query) ?? false) ||
                ($0.description?.lowercased().contains(query) ?? false)
            }
            mainsearchCollectionView.reloadData()
            
        case .books:
            filteredBooks = allBooks.filter {
                $0.title.lowercased().contains(query) ||
                $0.author.lowercased().contains(query)
            }
            mainsearchCollectionView.reloadData()
            
            GoogleBooksService.searchBooks(query: text) { [weak self] googleBooks in
                guard let self = self, searchController.searchBar.text == text else { return }
                let remoteBooks = googleBooks.map { $0.toBook() }
                
                var combined = self.filteredBooks
                for book in remoteBooks {
                    if !combined.contains(where: { $0.id == book.id }) {
                        combined.append(book)
                    }
                }
                
                DispatchQueue.main.async {
                    self.filteredBooks = combined
                    self.mainsearchCollectionView.reloadData()
                }
            }
        }
    }
}

// MARK: - UICollectionViewDataSource
extension searchViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        let isSearching = !(searchController.searchBar.text?.isEmpty ?? true)
        switch currentType {
        case .users: return 1
        case .books: return isSearching ? 1 : 3
        case .clubs: return isSearching ? 1 : 3
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let isSearching = !(searchController.searchBar.text?.isEmpty ?? true)
        switch currentType {
        case .users: return filteredUsers.count
        case .books:
            if isSearching { return filteredBooks.count }
            switch section {
            case 0: return suggestedBooks.count
            case 1: return trendingBooks.count
            case 2: return newReleases.count
            default: return 0
            }
        case .clubs:
            if isSearching { return filteredClubs.count }
            switch section {
            case 0: return suggestedClubs.count
            case 1: return trendingClubs.count
            case 2: return newClubs.count
            default: return 0
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch currentType {
        case .users:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "UserCollectionViewCell", for: indexPath) as! UserCollectionViewCell
            let user = filteredUsers[indexPath.item]
            cell.configure(with: user)
            cell.closeButton.isHidden = !(searchController.searchBar.text?.isEmpty ?? true)
            cell.onCloseTap = { [weak self] in
                guard let self = self else { return }
                self.recentUsers.removeAll(where: { $0.userId == user.userId })
                self.filteredUsers = self.recentUsers
                self.mainsearchCollectionView.reloadData()
            }
            return cell
            
        case .books:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BooksCollectionViewCell", for: indexPath) as! BooksCollectionViewCell
            let book: Book
            if !(searchController.searchBar.text?.isEmpty ?? true) {
                book = filteredBooks[indexPath.item]
            } else {
                switch indexPath.section {
                case 0: book = suggestedBooks[indexPath.item]
                case 1: book = trendingBooks[indexPath.item]
                case 2: book = newReleases[indexPath.item]
                default: fatalError()
                }
            }
            cell.configure(with: book)
            return cell
            
        case .clubs:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ClubCollectionViewCell", for: indexPath) as! ClubCollectionViewCell
            let club: Club
            if !(searchController.searchBar.text?.isEmpty ?? true) {
                club = filteredClubs[indexPath.item]
            } else {
                switch indexPath.section {
                case 0: club = suggestedClubs[indexPath.item]
                case 1: club = trendingClubs[indexPath.item]
                case 2: club = newClubs[indexPath.item]
                default: fatalError()
                }
            }
            cell.configureCell(club: club)
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "searchheader", for: indexPath) as! searchheader
        let isSearching = !(searchController.searchBar.text?.isEmpty ?? true)
        
        if isSearching {
            header.isHidden = true
            return header
        }
        
        header.isHidden = false
        switch currentType {
        case .books:
            let titles = ["Recommended", "Trending", "New Releases"]
            header.configure(title: titles[indexPath.section], section: indexPath.section)
        case .clubs:
            let titles = ["Suggested Clubs", "Trending Clubs", "New Clubs"]
            header.configure(title: titles[indexPath.section], section: indexPath.section)
        case .users:
            header.isHidden = true
        }
        return header
    }
}

// MARK: - UICollectionViewDelegate
extension searchViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch currentType {
        case .users:
            let user = filteredUsers[indexPath.item]
            if let idx = recentUsers.firstIndex(where: { $0.userId == user.userId }) {
                recentUsers.remove(at: idx)
            }
            recentUsers.insert(user, at: 0)
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let otherVC = storyboard.instantiateViewController(withIdentifier: "OtherUserProfileViewController") as? OtherUserProfileViewController {
                otherVC.profile = user
                navigationController?.pushViewController(otherVC, animated: true)
            }
            
        case .books:
            let isSearching = !(searchController.searchBar.text?.isEmpty ?? true)
            var selectedBook: Book?
            if isSearching {
                selectedBook = filteredBooks[indexPath.item]
            } else {
                switch indexPath.section {
                case 0: selectedBook = suggestedBooks[indexPath.item]
                case 1: selectedBook = trendingBooks[indexPath.item]
                case 2: selectedBook = newReleases[indexPath.item]
                default: break
                }
            }
            
            if let book = selectedBook {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                if let vc = storyboard.instantiateViewController(withIdentifier: "BookPresentationViewController") as? BookPresentationViewController {
                    vc.book = book
                    vc.bookshelfData = AppDependencies.shared.bookshelfData
                    present(vc, animated: true)
                }
            }
            
        case .clubs:
            let club: Club
            if !(searchController.searchBar.text?.isEmpty ?? true) {
                club = filteredClubs[indexPath.item]
            } else {
                switch indexPath.section {
                case 0: club = suggestedClubs[indexPath.item]
                case 1: club = trendingClubs[indexPath.item]
                case 2: club = newClubs[indexPath.item]
                default: return
                }
            }
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let vc = storyboard.instantiateViewController(withIdentifier: "KafkaViewController") as? KafkaViewController {
                vc.club = club
                vc.clubId = club.id ?? ""
                vc.clubData = self.clubData
                vc.clubDetailData = self.clubDetailData
                navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    private func showAddToShelfOptions(for book: Book) {
        let alert = UIAlertController(title: "Add to Bookshelf", message: "Choose a shelf for '\(book.title)'", preferredStyle: .actionSheet)
        for type in ShelfType.allCases {
            alert.addAction(UIAlertAction(title: type.displayName, style: .default) { _ in
                AppDependencies.shared.bookshelfData.move(book: book, to: type)
                let success = UIAlertController(title: "Added!", message: "'\(book.title)' has been added to your \(type.displayName) shelf.", preferredStyle: .alert)
                success.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(success, animated: true)
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        present(alert, animated: true)
    }
}

// MARK: - Layout Methods
extension searchViewController {
    func generateLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { sectionIndex, _ in
            switch self.currentType {
            case .users: return self.generateUserSection()
            case .books: return self.generateBookSection()
            case .clubs: return self.generateClubSection()
            }
        }
    }
    
    func generateUserSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(90))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(90))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 8
        section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        return section
    }
    
    func generateBookSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(110), heightDimension: .absolute(220))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(110), heightDimension: .absolute(220))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = 12
        section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 20, trailing: 16)
        
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(40))
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        section.boundarySupplementaryItems = [header]
        return section
    }
    
    func generateClubSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(211), heightDimension: .absolute(270))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, repeatingSubitem: item, count: 1)
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 14
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 20, trailing: 16)
        section.orthogonalScrollingBehavior = .continuous
        
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(40))
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        section.boundarySupplementaryItems = [header]
        return section
    }
}
