

import Foundation
import UIKit
struct FeedResponse: Codable {
    let title: String
    let posts: [FeedPost]
}

struct FeedPost: Codable, Identifiable, @unchecked Sendable {
    let id: String
    var userId: String?  //FK -> User
    
    var name: String
    let time: String
    
    let title: String
    let content: String
    
    var likeCount: Int
    var commentCount: Int
    var isLiked: Bool   //Default is false
    
    var postImage: String?
    var bookTitle: String?
    var bookAuthor: String?
    var bookCoverImage: String?
    var localImage: UIImage?
    
    var createdAt: Date? // 🔥 Required for sorting
    var avatarUrl: String?
    
    enum CodingKeys: String, CodingKey {
           case id, userId, name, time, title, content,
                likeCount, commentCount, isLiked,
                postImage, bookTitle, bookAuthor, bookCoverImage,
                createdAt, avatarUrl
       }
    var bookId: String?   // reference only
}

extension FeedPost {
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try? container.decode(String.self, forKey: .userId)
        name = try container.decode(String.self, forKey: .name)
        time = try container.decode(String.self, forKey: .time)
        title = try container.decode(String.self, forKey: .title)
        content = try container.decode(String.self, forKey: .content)
        likeCount = try container.decode(Int.self, forKey: .likeCount)
        commentCount = try container.decode(Int.self, forKey: .commentCount)
        isLiked = try container.decode(Bool.self, forKey: .isLiked)
        postImage = try? container.decode(String.self, forKey: .postImage)
        bookTitle = try? container.decode(String.self, forKey: .bookTitle)
        bookAuthor = try? container.decode(String.self, forKey: .bookAuthor)
        bookCoverImage = try? container.decode(String.self, forKey: .bookCoverImage)
        createdAt = try? container.decode(Date.self, forKey: .createdAt)
        avatarUrl = try? container.decode(String.self, forKey: .avatarUrl)
        localImage = nil
        bookId = nil
    }
}

extension UIImageView {
    private static let imageCache = NSCache<NSString, UIImage>()
    
    func loadFromUrl(_ urlString: String?, placeholder: UIImage? = UIImage(systemName: "person.circle.fill")) {
        guard let urlStr = urlString, !urlStr.isEmpty, urlStr != "person.circle.fill" else {
            // Silently use placeholder for nil, empty, or default system strings
            self.image = placeholder
            return
        }
        
        let secureURL = urlStr.hasPrefix("http") ? urlStr.replacingOccurrences(of: "http://", with: "https://") : urlStr
        
        if let cached = Self.imageCache.object(forKey: secureURL as NSString) {
            self.image = cached
            return
        }
        
        self.image = placeholder
        self.tintColor = .systemGray4
        
        guard let url = URL(string: secureURL) else { 
            print("❌ Invalid URL: \(secureURL)")
            return 
        }
        
        print("🚀 Loading image from: \(secureURL)")
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                print("❌ Image load error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data, let image = UIImage(data: data) else { 
                print("❌ Failed to decode image data from: \(secureURL)")
                return 
            }
            
            Self.imageCache.setObject(image, forKey: secureURL as NSString)
            DispatchQueue.main.async {
                self?.image = image
                self?.tintColor = .none
                print("✅ Successfully loaded image: \(secureURL)")
            }
        }.resume()
    }
}
