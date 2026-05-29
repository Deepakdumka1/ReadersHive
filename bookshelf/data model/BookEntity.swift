import Foundation

struct Book: Codable {

    let id: String
    let title: String
    let author: String
    let coverImageURL: String
   // let coverImageName : String// 🔥 only URL
    let description: String
    var genres: [String]?
}
// Shelf Section
struct ShelfSection: Codable{

    var id: ShelfType { shelfType }

    let shelfType: ShelfType
    let title: String
    var books: [BookRef] // what books inside this shelf
    var isPrivate: Bool
}

struct BookRef: Codable, Identifiable {
    
    let id : String
}

// Shelf  lists
enum ShelfType: String, Codable ,CaseIterable{

    case currentlyReading
    case wantToRead
    case finished
    case custom

    var displayName: String {
        switch self {
        case .currentlyReading:
            return "Currently Reading"
        case .wantToRead:
            return "Want To Read"
        case .finished:
            return "Finished"
        case .custom:
            return "custom"
        }
    }
}


