import Foundation

struct SuggestedResponse: Codable {
    let title: String
    let users: [SuggestedUser]
}

struct SuggestedUser: Codable, Identifiable {
    let id: String
    let username: String
    let name: String
    let avatarImage: String
    var isFollowing: Bool
}
