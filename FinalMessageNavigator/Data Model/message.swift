import Foundation
import FirebaseFirestore

// MARK: - Conversation
struct Conversation: Codable, Identifiable {
    let id: String
    let otherUserId: String
    let otherUserName: String
    let avatarImage: String
    let lastMessage: String
    let lastMessageTimestamp: Date?
    var messages: [Message] = []
    
    var lastMessageSnippet: String {
        return lastMessage
    }
    
    var lastMessageTime: String {
        guard let date = lastMessageTimestamp else { return "" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case otherUserId = "other_user_id"
        case otherUserName = "other_user_name"
        case avatarImage = "avatar_image"
        case lastMessage = "last_message"
        case lastMessageTimestamp = "last_message_timestamp"
    }
}

// MARK: - Message
struct Message: Codable, Identifiable {
    let id: String
    let senderId: String
    let content: String
    let timestamp: Date
    var isRead: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case senderId = "sender_id"
        case content
        case timestamp
        case isRead = "is_read"
    }
}
