import UIKit

class BookDetailViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var menuButton: UIBarButtonItem!
    
    var bookshelfData: BookshelfData?
    var section: ShelfSection?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("BookDetailViewController loaded")
        print("bookshelfData =", bookshelfData as Any)
        print("section =", section as Any)
        
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
        updateTitle()
        setupFilterMenu()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadTable),
            name: NSNotification.Name("bookMoved"),
            object: nil
        )
        
    }
    func updateTitle() {
        guard let section = section else { return }
        title = "\(section.title)"
       
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadTable()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Reload Table
    @objc func reloadTable() {
        print("Reloading table")
        
        guard let bookshelfData = bookshelfData else {
            print("bookshelfData is nil in BookDetailViewController")
            return
        }
        
        if let current = section {
            section = bookshelfData.sections.first(where: { $0.shelfType == current.shelfType })
        }
        
        tableView.reloadData()
    }
    
    // MARK: - Open Add Book Screen
    func openAddBookScreen() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        guard let vc = storyboard.instantiateViewController(
            withIdentifier: "AddBookViewController"
        ) as? AddBookViewController else { return }
        
        print("Passing bookshelfData =", bookshelfData as Any)
        
        vc.bookshelfData = bookshelfData
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: - Setup Menu
    private func setupFilterMenu() {
        
        let addBookAction = UIAction(
            title: "Add Book",
            image: UIImage(systemName: "plus")
        ) { [weak self] _ in
            self?.openAddBookScreen()
        }
        
        let removeAction = UIAction(
            title: "Remove From List",
            image: UIImage(systemName: "minus.circle")
        ) { [weak self] _ in
            
            guard let self = self else { return }
            
            let alert = UIAlertController(
                title: "Remove Books",
                message: "Swipe left on a book to remove it from the list.",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Got it", style: .default))
            
            self.present(alert, animated: true)
        }
        
        let shareAction = UIAction(
            title: "Share",
            image: UIImage(systemName: "square.and.arrow.up")
        ) { _ in
            print("Share tapped")
            self.shareList()
        }
        
        let togglePrivacyAction = UIAction(
            title: (section?.isPrivate ?? false) ? "Make Public" : "Make Private",
            image: UIImage(systemName: (section?.isPrivate ?? false) ? "globe" : "lock")
        ) { [weak self] _ in
            self?.togglePrivacy()
        }
        
        var menuActions = [
            addBookAction,
            removeAction,
            shareAction,
            togglePrivacyAction
        ]
        
        if section?.shelfType == .custom {
            let deleteListAction = UIAction(
                title: "Delete List",
                image: UIImage(systemName: "trash"),
                attributes: .destructive
            ) { [weak self] _ in
                self?.confirmDeleteList()
            }
            menuActions.append(deleteListAction)
        }
        
        let menu = UIMenu(children: menuActions)
        
        menuButton.menu = menu
        menuButton.primaryAction = nil
    }
    
    private func confirmDeleteList() {
        guard let currentSection = section,
              let bookshelfData = bookshelfData else { return }
              
        let alert = UIAlertController(
            title: "Delete List",
            message: "Are you sure you want to delete the list '\(currentSection.title)'? This will remove all books saved in this list.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            
            bookshelfData.deleteSection(currentSection)
            self.navigationController?.popViewController(animated: true)
        })
        
        present(alert, animated: true)
    }
    func shareList() {
        
        guard let section = section,
              let bookshelfData = bookshelfData else {
            print("❌ section or data is nil")
            return
        }
        
        let books = bookshelfData.getBooks(for: section)
        
        var shareText = "📚 My Reading List: \(section.title)\n\n"
        
        for book in books {
            shareText += "• \(book.title) — \(book.author)\n"
        }
        
        if books.isEmpty {
            shareText += "No books yet."
        }
        
        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        // ✅ SAFE iPad handling
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = self.view   // safer than menuButton
            popover.sourceRect = CGRect(
                x: self.view.bounds.midX,
                y: self.view.bounds.midY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }
        
        present(activityVC, animated: true)
    }
    func togglePrivacy() {
        guard let currentSection = section,
              let bookshelfData = bookshelfData else { return }

        guard let index = bookshelfData.sections.firstIndex(where: { $0.shelfType == currentSection.shelfType }) else {
            return
        }

        // Toggle privacy
        bookshelfData.sections[index].isPrivate.toggle()

        // Update local section immediately
        section = bookshelfData.sections[index]

        // Update UI immediately
        updateTitle()
        setupFilterMenu()

        // Refresh bookshelf screen
        NotificationCenter.default.post(
            name: NSNotification.Name("bookMoved"),
            object: nil
        )

        print("Privacy changed instantly:", section?.isPrivate ?? false)
    }
    
    // MARK: - Delete Book
    func deleteBook(_ book: Book) {
        guard let currentSection = section,
              let bookshelfData = bookshelfData else { return }

        guard let sectionIndex = bookshelfData.sections.firstIndex(where: { $0.title == currentSection.title }) else {
            return
        }

        bookshelfData.sections[sectionIndex].books.removeAll { $0.id == book.id }

        NotificationCenter.default.post(
            name: NSNotification.Name("bookMoved"),
            object: nil
        )

        reloadTable()
    }
}

// MARK: - UITableViewDataSource
extension BookDetailViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        
        guard let section = self.section,
              let bookshelfData = bookshelfData else { return 0 }
        
        let books = bookshelfData.getBooks(for: section)
        return books.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "bookDetailCell1",
            for: indexPath
        ) as! bookDetailCell1
        
        guard let section = self.section,
              let bookshelfData = bookshelfData else { return cell }
        
        let books = bookshelfData.getBooks(for: section)
        
        if indexPath.row < books.count {
            let book = books[indexPath.row]
            cell.configure(with: book)
        }
        
        cell.accessoryType = .none
        cell.selectionStyle = .none
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension BookDetailViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Later:
        // Open book detail screen here if you want
    }
    
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        guard let currentSection = section,
              let bookshelfData = bookshelfData else { return nil }
        
        let books = bookshelfData.getBooks(for: currentSection)
        guard indexPath.row < books.count else { return nil }
        
        let book = books[indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            guard let self = self else {
                completion(false)
                return
            }
            
            self.deleteBook(book)
            completion(true)
        }
        
        deleteAction.image = UIImage(systemName: "trash")
        
        let config = UISwipeActionsConfiguration(actions: [deleteAction])
        config.performsFirstActionWithFullSwipe = true
        
        return config
    }
}
