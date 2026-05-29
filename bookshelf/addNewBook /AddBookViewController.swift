//
//  AddBookViewController.swift
//  Club
//
//  Created by Pawan Bisht on 16/03/26.
//

import UIKit

class AddBookViewController: UIViewController{
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var searchBookcollectionView: UICollectionView!
    var targetSection: ShelfSection?
    var suggestedBooks: [Book] = []
    var newReleases: [Book] = []
    var trendingBooks: [Book] = []
    var bookshelfData: BookshelfData?    // for searching
    var allBooks: [Book] = []
    var filteredBooks: [Book] = []
    var isSearching: Bool = false
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Add Book"
        
        searchBookcollectionView.dataSource = self
        searchBookcollectionView.delegate = self
        
        // register cell
        searchBookcollectionView.register(
            UINib(nibName: "BooksCollectionViewCell", bundle: nil),
            forCellWithReuseIdentifier: "BooksCollectionViewCell"
        )
        
        // register header
        searchBookcollectionView.register(
            UINib(nibName: "Section1HeaderView", bundle: nil),
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "Section1HeaderView"
        )
        
        searchBookcollectionView.collectionViewLayout = generateLayout()
        
        //for style floating bar search
        searchBookcollectionView.contentInset.bottom = 80
        searchBookcollectionView.verticalScrollIndicatorInsets.bottom = 80
        
        // search button style
        searchBar.layer.cornerRadius = 28
        searchBar.layer.masksToBounds = false

        searchBar.layer.shadowColor = UIColor.black.cgColor
        searchBar.layer.shadowOpacity = 0.15
        searchBar.layer.shadowOffset = CGSize(width: 0, height: 4)
        searchBar.layer.shadowRadius = 8
        
        // to replace background
        let blur = UIBlurEffect(style: .systemMaterial)
        let blurView = UIVisualEffectView(effect: blur)

        blurView.frame = searchBar.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        navigationItem.largeTitleDisplayMode = .never
        searchBar.insertSubview(blurView, at: 0)
        searchBar.delegate = self
 
        loadBooks()
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if segue.identifier == "showBookCard" {
            let vc = segue.destination as! BookPresentationViewController
            vc.bookshelfData = bookshelfData
            vc.book = sender as? Book
        }
    }
    func loadBooks() {
        guard let bookshelf = bookshelfData else {
            print(" bookshelfData is nil in AddBookViewController")
            return
        }

        allBooks = bookshelf.allBooks
        filteredBooks = allBooks

        suggestedBooks = Array(allBooks.prefix(6))
        newReleases = Array(allBooks.dropFirst(6).prefix(6))
        trendingBooks = Array(allBooks.dropFirst(12).prefix(6))

        searchBookcollectionView.reloadData()
    }
//    @objc func searchTextChanged() {
//
//        let text = searchBar.text?.lowercased() ?? ""
//
//        if text.isEmpty {
//            isSearching = false
//            filteredBooks = []
//        } else {
//            isSearching = true
//
//            filteredBooks = allBooks.filter {
//                $0.title.lowercased().contains(text) ||
//                $0.author.lowercased().contains(text)
//            }
//        }
//
//        searchBookcollectionView.reloadData()
//        searchBookcollectionView.setCollectionViewLayout(generateLayout(), animated: false)
//    }

}



extension AddBookViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if isSearching{
            return 1 // only one section for search result
        }
        return 3
    }
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        if isSearching {
            return filteredBooks.count
        }
        switch section {
            
        case 0:
            return suggestedBooks.count
            
        case 1:
            return newReleases.count
            
        case 2:
            return trendingBooks.count
            
        default:
            return 0
        }
    }
    //load book cell
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath)
    -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "BooksCollectionViewCell",
            for: indexPath
        ) as! BooksCollectionViewCell

        let book: Book

        if isSearching {
            book = filteredBooks[indexPath.item]
        } else {
            switch indexPath.section {
            case 0: book = suggestedBooks[indexPath.item]
            case 1: book = newReleases[indexPath.item]
            case 2: book = trendingBooks[indexPath.item]
            default: fatalError("Invalid section")
            }
        }

        cell.configure(with: book)
        return cell
    }
    
    
    
    
    
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath)
    -> UICollectionReusableView {

        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: "Section1HeaderView",
            for: indexPath
        ) as! HeaderView

        if isSearching {
            header.isHidden = true
            return header
        }

        header.isHidden = false

        switch indexPath.section {

        case 0:
            header.configure(title: "Suggested", section: indexPath.section)

        case 1:
            header.configure(title: "New Releases", section: indexPath.section)

        case 2:
            header.configure(title: "Trending", section: indexPath.section)

        default:
            break
        }

        return header
    }
    
    func generateLayout() -> UICollectionViewLayout {

        return UICollectionViewCompositionalLayout { sectionIndex, _ in
            return self.generateSection()
        }
    }
    
    func generateSection() -> NSCollectionLayoutSection {

        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(200)
        )

        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .absolute(110),
            heightDimension: .absolute(200)
        )

        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: groupSize,
            subitems: [item]
        )

        let section = NSCollectionLayoutSection(group: group)

        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = 12

        section.contentInsets = NSDirectionalEdgeInsets(
            top: 4,
            leading: 16,
            bottom: 20,
            trailing: 16
        )

        // header
        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(40)
        )

        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )

        section.boundarySupplementaryItems = [header]

        return section
    }
}
extension AddBookViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {

        let text = searchText.lowercased()

        if text.isEmpty {
            isSearching = false
            filteredBooks = []
            searchBookcollectionView.reloadData()
        } else {
            isSearching = true

            filteredBooks = allBooks.filter {
                $0.title.lowercased().contains(text) ||
                $0.author.lowercased().contains(text)
            }
            searchBookcollectionView.reloadData()
            
            GoogleBooksService.searchBooks(query: text) { [weak self] googleBooks in
                guard let self = self, searchBar.text?.lowercased() == text else { return }
                let remoteBooks = googleBooks.map { $0.toBook() }
                
                var combined = self.filteredBooks
                for book in remoteBooks {
                    if !combined.contains(where: { $0.id == book.id }) {
                        combined.append(book)
                    }
                }
                
                DispatchQueue.main.async {
                    self.filteredBooks = combined
                    self.searchBookcollectionView.reloadData()
                }
            }
        }
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}


extension AddBookViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {

        let selectedBook: Book

        if isSearching {
            selectedBook = filteredBooks[indexPath.item]
        } else {
            switch indexPath.section {
            case 0: selectedBook = suggestedBooks[indexPath.item]
            case 1: selectedBook = newReleases[indexPath.item]
            case 2: selectedBook = trendingBooks[indexPath.item]
            default: return
            }
        }

        openBookCard(book: selectedBook)
    }
    func openBookCard(book: Book) {

        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        guard let vc = storyboard.instantiateViewController(
            withIdentifier: "BookPresentationViewController"
        ) as? BookPresentationViewController else {
            print("VC not found")
            return
        }

        vc.book = book
        vc.bookshelfData = bookshelfData

        vc.modalTransitionStyle = .crossDissolve
        present(vc, animated: true)    }
    
}
