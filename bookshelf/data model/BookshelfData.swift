import Foundation
import FirebaseFirestore
import FirebaseAuth

class BookshelfData {
    
    var allBooks: [Book] = [] 
    var sections: [ShelfSection] = [] 
    
    var bookMap: [String: Book] {
        return Dictionary(uniqueKeysWithValues: allBooks.map { ($0.id, $0) })
    }
    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()

    init() {
        self.sections = [
            ShelfSection(shelfType: .currentlyReading, title: "Currently Reading", books: [], isPrivate: false),
            ShelfSection(shelfType: .wantToRead, title: "Want To Read", books: [], isPrivate: false),
            ShelfSection(shelfType: .finished, title: "Finished", books: [], isPrivate: false)
        ]
        self.allBooks = []
        
        // Start listening if user is logged in
        listen()
    }
    
    func listen(completion: (() -> Void)? = nil) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        listener?.remove()
        listener = db.collection("bookshelves").document(currentUserId).addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Bookshelf sync error: \(error)")
                return
            }
            
            if let data = snapshot?.data(),
               let sectionsData = data["sections"] as? [[String: Any]] {
                
                // Parse sections
                var updatedSections: [ShelfSection] = []
                for sectionDict in sectionsData {
                    if let typeStr = sectionDict["shelfType"] as? String,
                       let type = ShelfType(rawValue: typeStr),
                       let title = sectionDict["title"] as? String,
                       let booksArray = sectionDict["books"] as? [[String: Any]] {
                        
                        var bookRefs: [BookRef] = []
                        for b in booksArray {
                            if let id = b["id"] as? String {
                                bookRefs.append(BookRef(id: id))
                            }
                        }
                        
                        updatedSections.append(ShelfSection(
                            shelfType: type,
                            title: title,
                            books: bookRefs,
                            isPrivate: sectionDict["isPrivate"] as? Bool ?? false
                        ))
                    }
                }
                
                // Parse allBooks (cache)
                if let booksData = data["allBooks"] as? [[String: Any]] {
                    self.allBooks = booksData.compactMap { dict -> Book? in
                        guard let id = dict["id"] as? String,
                              let title = dict["title"] as? String,
                              let author = dict["author"] as? String,
                              let url = dict["coverImageURL"] as? String else { return nil }
                        return Book(id: id, title: title, author: author, coverImageURL: url, description: dict["description"] as? String ?? "")
                    }
                }
                
                if !updatedSections.isEmpty {
                    self.sections = updatedSections
                }
                
                print("📚 Bookshelf updated from Firestore")
                NotificationCenter.default.post(name: NSNotification.Name("bookshelfUpdated"), object: nil)
                completion?()
            } else {
                // If no data, maybe seed with defaults
                self.save()
            }
        }
    }
    
    func save() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // Convert to dictionary for Firestore
        let sectionsDict = sections.map { section -> [String: Any] in
            return [
                "shelfType": section.shelfType.rawValue,
                "title": section.title,
                "isPrivate": section.isPrivate,
                "books": section.books.map { ["id": $0.id] }
            ]
        }
        
        let booksDict = allBooks.map { book -> [String: Any] in
            return [
                "id": book.id,
                "title": book.title,
                "author": book.author,
                "coverImageURL": book.coverImageURL,
                "description": book.description
            ]
        }
        
        db.collection("bookshelves").document(currentUserId).setData([
            "sections": sectionsDict,
            "allBooks": booksDict
        ], merge: true)
    }

    func getBooks(for section: ShelfSection) -> [Book] {
        return section.books.compactMap { ref in
            allBooks.first { $0.id == ref.id }
        }
    }
    
    func books(for shelf: ShelfType) -> [Book] {
        guard let section = sections.first(where: { $0.shelfType == shelf }) else {
            return []
        }
        return getBooks(for: section)
    }
    
    func move(book: Book, to shelf: ShelfType) {
        addBookIfNeeded(book)

        // remove from all
        for i in 0..<sections.count {
            sections[i].books.removeAll { $0.id == book.id }
        }

        // add to selected
        if let index = sections.firstIndex(where: { $0.shelfType == shelf }) {
            sections[index].books.append(BookRef(id: book.id))
        }

        save() // Persistence
        
        NotificationCenter.default.post(name: NSNotification.Name("bookMoved"), object: nil)
    }

    func addBookIfNeeded(_ book: Book) {
        if !allBooks.contains(where: { $0.id == book.id }) {
            allBooks.append(book)
        }
    }
    
    func section(for shelf: ShelfType) -> ShelfSection? {
        return sections.first { $0.shelfType == shelf }
    }
    
    func deleteSection(_ section: ShelfSection) {
        sections.removeAll { $0.title == section.title && $0.shelfType == section.shelfType }
        save()
        NotificationCenter.default.post(name: NSNotification.Name("bookMoved"), object: nil)
    }
}
