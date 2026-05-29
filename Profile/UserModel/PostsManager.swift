import Foundation

class PostsManager {
    static let shared = PostsManager()
    
    private init() {}
    
    func fetchMyPosts() -> [FeedPost] {
        guard let url = Bundle.main.url(forResource: "my_posts", withExtension: "json") else {
            print("my_posts.json not found in bundle.")
            return []
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let posts = try decoder.decode([FeedPost].self, from: data)
            return posts
        } catch {
            print("Failed to decode my_posts.json:", error)
            return []
        }
    }
}
