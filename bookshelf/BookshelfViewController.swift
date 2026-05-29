//
//  ViewController.swift
//  shelf_start
//
//  Created by GEU on 10/02/26.
//

import UIKit

class BookshelfViewController: UIViewController ,NewListDelegate{
    func didCreateList(name: String, isPrivate: Bool) {

        let newSection = ShelfSection(
            shelfType: .custom,
            title: name,
            books: [],
            isPrivate: isPrivate   //  from switch
        )

        book.sections.append(newSection)
        book.save()

        ColllectionView.reloadData()

        NotificationCenter.default.post(
            name: NSNotification.Name("listCreated"),
            object: nil
        )
    }
    
   
   
    @IBAction func addListButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: "newList", sender: nil)
    }
    var selectedSection: ShelfSection?

    var book: BookshelfData!
 //   let section = BookshelfData.shared.sections[indexPath.section]
    func didTapHeader(section: Int) {
        selectedSection = sections[section]
        performSegue(withIdentifier: "showBookDetail", sender: nil)
     
      
    }
    
    
    func didCreateList(name: String) {

        let newSection = ShelfSection(
            shelfType: .custom,
            title: name,
            books: [],
            isPrivate: false
        )


        book.sections.append(newSection)
        book.save()

     

        ColllectionView.reloadData()

        //  update ui
        NotificationCenter.default.post(
            name: NSNotification.Name("listCreated"),
            object: nil
        )
    }


    @IBOutlet var ColllectionView: UICollectionView!
    //var book = BookshelfData()
    var bookList : [Book] = []
    var bookwantto : [Book] = []
    var bookfinished : [Book] = []
    var sections: [ShelfSection]{
        return book.sections
    }

 
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Bookshelf"
        
        // 🔥 USE SHARED DATA (CRITICAL FOR SYNC)
        book = AppDependencies.shared.bookshelfData
        
        // Register cells and headers
        ColllectionView.register(UINib(nibName: "TopBookCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "TopBookCollectionViewCell")
        ColllectionView.register(UINib(nibName: "BookshelfSectionHeaderView", bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "BookshelfSectionHeaderView")
        
        ColllectionView.collectionViewLayout = generateLayout()
        ColllectionView.dataSource = self
        ColllectionView.delegate = self
        
        // 🔥 LISTEN FOR ALL UPDATES
        NotificationCenter.default.addObserver(self, selector: #selector(reloadCollection), name: NSNotification.Name("bookMoved"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadCollection), name: NSNotification.Name("bookshelfUpdated"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadCollection), name: NSNotification.Name("listCreated"), object: nil)
    }
    @objc func reloadCollection() {
        ColllectionView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if segue.identifier == "newList" {

            let navVC = segue.destination as! UINavigationController
             let vc = navVC.topViewController as! newListViewController
            vc.delegate = self
        }

        else if segue.identifier == "showSectionDetail" {

            let vc = segue.destination as! BookDetailViewController
            vc.bookshelfData = book
            segue.destination.hidesBottomBarWhenPushed = true

            if let sectionIndex = sender as? Int {
                vc.section = sections[sectionIndex]
            }
        }
        else if segue.identifier == "showAddBookFromShelf" {
            let vc = segue.destination as! AddBookViewController
            vc.bookshelfData = book
            vc.targetSection = selectedSection
            vc.hidesBottomBarWhenPushed = true
            segue.destination.hidesBottomBarWhenPushed = true

        }
        else if segue.identifier == "showBookCard" {

            guard let vc = segue.destination as? BookPresentationViewController else {
                print("Destination is not BookPresentationViewController")
                return
            }

            vc.bookshelfData = book
            if let selectedBook = sender as? Book {
                vc.book = selectedBook
            }
        }
    }

}
extension BookshelfViewController: UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        let books = book.getBooks(for: sections[section])
        return books.count
    }
    
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sections.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "TopBookCollectionViewCell",
            for: indexPath
        ) as! TopBookCollectionViewCell
        
        let books = book.getBooks(for: sections[indexPath.section])
        
        if books.isEmpty {
            cell.showEmptyState(slot: indexPath.item + 1)
        } else if indexPath.item < books.count {
            let currentBook = books[indexPath.item]
            cell.configure(with: currentBook, rank: indexPath.item + 1)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        
        print(" Header created for section:", indexPath.section)
        
        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: "BookshelfSectionHeaderView",
            for: indexPath
        ) as! BookshelfSectionHeaderView
        
        let section = sections[indexPath.section]

        header.configure(
            title: section.title,
            isPrivate: section.isPrivate
        )
        
        header.buttonAction = { [weak self] in
            self?.performSegue(
                withIdentifier: "showSectionDetail",
                sender: indexPath.section
            )
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
            heightDimension: .absolute(90)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.78),   // ✅ reduced width so next group peeks
            heightDimension: .absolute(300)          // ✅ fixed height
        )

        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: groupSize,
            subitems: [item]
        )

        group.interItemSpacing = .fixed(8)

        let section = NSCollectionLayoutSection(group: group)

        // ✅ Enable horizontal scroll
        section.orthogonalScrollingBehavior = .continuous

        section.interGroupSpacing = 16
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 16,
            leading: 16,
            bottom: 16,
            trailing: 16
        )

        // ✅ HEADER
        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(44)
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

extension BookshelfViewController: UICollectionViewDelegate {
    
//    func collectionView(_ collectionView: UICollectionView,
//                        didSelectItemAt indexPath: IndexPath) {
//
//        let selectedSection = sections[indexPath.section]
//
//
//    }
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {

        let currentSection = sections[indexPath.section]
        let books = book.getBooks(for: currentSection)

        // If empty slot tapped → open Add Book
       
            if books.isEmpty || indexPath.item >= books.count {
                selectedSection = currentSection
                openAddBookScreen()
                return
            }
        // Otherwise open book card
        let selectedBook = books[indexPath.item]
        performSegue(withIdentifier: "showBookCard", sender: selectedBook)
    }
    func openAddBookScreen() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        guard let vc = storyboard.instantiateViewController(
            withIdentifier: "AddBookViewController"
        ) as? AddBookViewController else {
            print("Could not open AddBookViewController")
            return
        }

        vc.bookshelfData = book
        vc.targetSection = selectedSection
        vc.hidesBottomBarWhenPushed = true

        navigationController?.pushViewController(vc, animated: true)
    }
}
