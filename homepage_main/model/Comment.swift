import Foundation

struct PostComment: Codable, Identifiable {
    var id: String
    var postId: String
    var userId: String
    var userName: String
    var userAvatarUrl: String?
    var content: String
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case postId
        case userId
        case userName
        case userAvatarUrl
        case content
        case createdAt
    }
}
