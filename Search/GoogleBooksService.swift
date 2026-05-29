import Foundation

struct GoogleBooksResponse: Codable, Sendable {
    let items: [GoogleBook]?
}

struct GoogleBook: Codable, Sendable {
    let id: String
    let volumeInfo: VolumeInfo
    
    func toBook() -> Book {
        return Book(
            id: id,
            title: volumeInfo.title ?? "Untitled",
            author: volumeInfo.authors?.joined(separator: ", ") ?? "Unknown Author",
            coverImageURL: volumeInfo.imageLinks?.thumbnail?.replacingOccurrences(of: "http:", with: "https:") ?? "",
            description: volumeInfo.description ?? "No description available.",
            genres: volumeInfo.categories
        )
    }
}

struct VolumeInfo: Codable, Sendable {
    let title: String?
    let authors: [String]?
    let description: String?
    let pageCount: Int?
    let categories: [String]?
    let averageRating: Double?
    let imageLinks: ImageLinks?
    let previewLink: String?
}

struct ImageLinks: Codable, Sendable {
    let thumbnail: String?
}

class GoogleBooksService {
    
    static let apiKey = "AIzaSyBrUORhTKUboiHrVsVnYaPP8nza60J9-jg"
    
    static func fetchDefaultBooks(query: String, completion: @escaping ([GoogleBook]) -> Void) {
        let formattedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://www.googleapis.com/books/v1/volumes?q=\(formattedQuery)&maxResults=10&key=\(apiKey)"
        
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("❌ Google Books API Error: \(error)")
                return
            }
            
            guard let data = data else { return }
            
            do {
                let result = try JSONDecoder().decode(GoogleBooksResponse.self, from: data)
                
                let cleanBooks = (result.items ?? []).filter { book in
                    let title = book.volumeInfo.title?.lowercased() ?? ""
                    if title.contains("summary") || title.contains("guide") || title.contains("workbook") { return false }
                    if book.volumeInfo.imageLinks?.thumbnail == nil { return false }
                    if title.trimmingCharacters(in: .whitespaces).isEmpty { return false }
                    return true
                }
                
                DispatchQueue.main.async {
                    completion(cleanBooks)
                }
            } catch {
                print("❌ Decoding Error:", error)
            }
        }.resume()
    }
    
    static func searchBooks(query: String, completion: @escaping ([GoogleBook]) -> Void) {
        let formattedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://www.googleapis.com/books/v1/volumes?q=intitle:\(formattedQuery)&maxResults=20&key=\(apiKey)"
        
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("❌ Google Books API Error: \(error)")
                return
            }
            
            guard let data = data else { return }
            
            do {
                let result = try JSONDecoder().decode(GoogleBooksResponse.self, from: data)
                
                // CLEAN DATA HERE
                let cleanBooks = (result.items ?? []).filter { book in
                    let title = book.volumeInfo.title?.lowercased() ?? ""
                    
                    // remove junk
                    if title.contains("summary") || title.contains("guide") || title.contains("workbook") {
                        return false
                    }
                    
                    // remove no image
                    if book.volumeInfo.imageLinks?.thumbnail == nil {
                        return false
                    }
                    
                    // remove empty titles
                    if title.trimmingCharacters(in: .whitespaces).isEmpty {
                        return false
                    }
                    
                    return true
                }
                
                DispatchQueue.main.async {
                    completion(cleanBooks)
                }
                
            } catch {
                print("❌ Decoding Error:", error)
            }
        }.resume()
    }
}
