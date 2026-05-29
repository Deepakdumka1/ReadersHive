//
//  tagBookViewController.swift
//  Club
//
//  Created by Pawan Bisht on 11/04/26.
//

import UIKit

protocol TagBookViewControllerDelegate: AnyObject {
    func didSelectBook(_ book: Book)
}

class tagBookViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UISearchBarDelegate {
    //var bookshelfData: BookshelfData?
    weak var delegate: TagBookViewControllerDelegate?
    var bookshelfData = AppDependencies.shared.bookshelfData
    override func viewDidLoad() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )
        
        super.viewDidLoad()
                collectionView.delegate = self
          collectionView.dataSource = self
          searchBar.delegate = self
        loadBooks()
//          collectionView.register(
//              UINib(nibName: "BookCollectionViewCell", bundle: nil),
//              forCellWithReuseIdentifier: "BookCollectionViewCell"
//
//          )
        collectionView.register(
            UINib(nibName: "BookCollectionViewCell", bundle: nil),
            forCellWithReuseIdentifier: "BookCollectionViewCell"
        )
        collectionView.register(
            UINib(nibName: "recentbookHeaderView", bundle: nil),
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "recentbookHeaderView"
        )
          updateUI()
    }
    @objc func closeTapped() {
        dismiss(animated: true)
    }
   // var allBooks: [Book] = []
    func loadBooks() {
        var combinedBooks = bookshelfData.allBooks
        
        let trendingBooks = AppDependencies.shared.trendingBooksData.books.map { tBook in
            Book(id: tBook.id, title: tBook.title, author: tBook.author, coverImageURL: tBook.coverImage, description: "Trending")
        }
        
        combinedBooks.append(contentsOf: trendingBooks)
        
        // Remove duplicates by title
        var uniqueBooks = [Book]()
        var seenTitles = Set<String>()
        for book in combinedBooks {
            let lowerTitle = book.title.lowercased()
            if !seenTitles.contains(lowerTitle) {
                seenTitles.insert(lowerTitle)
                uniqueBooks.append(book)
            }
        }
        
        allBooks = uniqueBooks
        filteredBooks = allBooks
        
        collectionView.reloadData()
    }
    var allBooks: [Book] = []
   // var filteredBooks: [Book] = []
//    var allBooks: [Book] = [
//        Book(id: UUID().uuidString, title: "Atomic Habits", author: "James Clear", coverImageName: "atomic_habits", description: "Build good habits and break bad ones with practical strategies."),
//        Book(id: UUID().uuidString, title: "Ikigai", author: "Hector Garcia", coverImageName: "ikigai", description: "A journey to discover your reason for being and a long, happy life."),
//        Book(id: UUID().uuidString, title: "The Alchemist", author: "Paulo Coelho", coverImageName: "alchemist", description: "A fable about following your dreams and personal legend.")
//    ]        // all books
    var filteredBooks: [Book] = []  // search results
    var recentBooks: [Book] {
        get { BookManager.recentBooks }
        set { BookManager.recentBooks = newValue }
    }    // recent
    //var filteredBooks: [Book] = []
    var isSearching = false
    private var searchTimer: Timer?
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var emptyStateView: UIView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    
    @IBAction func closebutton(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    class BookManager {
        static var recentBooks: [Book] = []
    }
    
    func updateUI() {
        
        if isSearching {
            emptyStateView.isHidden = true
            collectionView.isHidden = false
        } else {
            emptyStateView.isHidden = !recentBooks.isEmpty
            collectionView.isHidden = recentBooks.isEmpty
        }
        print("isSearching:", isSearching)
        print("empty hidden:", emptyStateView.isHidden)
        print("collection hidden:", collectionView.isHidden)
        collectionView.reloadData()
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if isSearching {
            return filteredBooks.count
        } else {
            return recentBooks.count
        }
    }
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            isSearching = false
            filteredBooks = []
            updateUI()
        } else {
            isSearching = true
            
            // First search locally
            let localResults = allBooks.filter {
                $0.title.lowercased().contains(searchText.lowercased()) ||
                $0.author.lowercased().contains(searchText.lowercased())
            }
            filteredBooks = localResults
            updateUI()
            
            // Debounce API search
            searchTimer?.invalidate()
            searchTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
                guard let self = self, self.isSearching, self.searchBar.text == searchText else { return }
                
                GoogleBooksService.searchBooks(query: searchText) { googleBooks in
                    let apiBooks = googleBooks.map { $0.toBook() }
                    
                    DispatchQueue.main.async {
                        // Merge and avoid duplicates
                        var merged = localResults
                        var seen = Set(localResults.map { $0.title.lowercased() })
                        
                        for book in apiBooks {
                            if !seen.contains(book.title.lowercased()) {
                                seen.insert(book.title.lowercased())
                                merged.append(book)
                            }
                        }
                        
                        self.filteredBooks = merged
                        self.updateUI()
                    }
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "BookCollectionViewCell",
            for: indexPath
        ) as! BookCollectionViewCell
        
        let book = isSearching
            ? filteredBooks[indexPath.item]
            : recentBooks[indexPath.item]
        
        cell.configure(with: book)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionView.elementKindSectionHeader {
            
            let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: "recentbookHeaderView",
                for: indexPath
            ) as! recentbookHeaderView
            
            header.configure(title: "Recent Books")
            
            return header
        }
        
        return UICollectionReusableView()
    }
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        // 🔥 Only show header if recent exists
        if !recentBooks.isEmpty && !isSearching {
            return CGSize(width: collectionView.frame.width, height: 40)
        }
        
        return .zero
    }
}
extension tagBookViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: collectionView.frame.width, height: 80)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let book = isSearching ? filteredBooks[indexPath.item] : recentBooks[indexPath.item]
        
        if !recentBooks.contains(where: { $0.title == book.title }) {
            recentBooks.insert(book, at: 0)
        }

        if recentBooks.count > 5 {
            recentBooks.removeLast()
        }
        
        delegate?.didSelectBook(book)
        
        dismiss(animated: true)
    }
}
