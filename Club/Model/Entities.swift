//
//  Entities.swift
//  Club
//
//  Created by GEU on 05/02/26.
//

import Foundation
import UIKit
import FirebaseAuth

// MARK: - Current User (simulated logged-in user)
let currentUserId = "temp_user_1"

// MARK: - Club (ER: CLUBS table)
struct Club: Codable, Identifiable {
    let id: String?
    let name: String?
    let category: ClubCategory?
    let description: String?
    var imagePath: String?
    let memberCount: Int?
    let language: String?
    var members: [ClubMember]?
    let section: ClubSection?
    var createdBy: String?       // FK → User.id
    let visibility: String?      // ER field
    var localImage: UIImage?     // UI-only property for uploads

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case category
        case description
        case imagePath = "image_path"
        case memberCount = "member_count"
        case language
        case members
        case section
        case createdBy = "created_by"
        case visibility
    }
}

// MARK: - Membership Helpers
func isUserMember(_ club: Club) -> Bool {
    guard let userId = Auth.auth().currentUser?.uid else { return false }
    return club.members?.contains(where: { $0.userId == userId }) ?? false
}

func isUserAdmin(_ club: Club) -> Bool {
    guard let userId = Auth.auth().currentUser?.uid else { return false }
    return club.members?.contains(where: { $0.userId == userId && $0.role == "admin" }) ?? false
}


struct ClubList: Codable {
    let title: String
    let imageName: String
}


// MARK: - Club Category Enum
enum ClubCategory: String, CaseIterable, Codable {
    case dark
    case poetry
    case classics
    case philosophy
    case fantasy

    var displayName: String {
        switch self {
        case .dark: return "Dark"
        case .poetry: return "Poetry"
        case .classics: return "Classics"
        case .philosophy: return "Philosophy"
        case .fantasy: return "Fantasy"
        }
    }

    var icon: String {
        switch self {
        case .dark: return "🕯️"
        case .poetry: return "📝"
        case .classics: return "📚"
        case .philosophy: return "🏛️"
        case .fantasy: return "🐉"
        }
    }
}

// MARK: - Club Section Enum
enum ClubSection: String, CaseIterable, Codable {
    case myClubs = "my_clubs"
    case recommended
    case trending

    var displayName: String {
        switch self {
        case .myClubs: return "My Clubs"
        case .recommended: return "Recommended"
        case .trending: return "Trending"
        }
    }
}

// Create Club section Enum
enum CreateClubSection: Int, CaseIterable {
    case image
    case name
    case description
    case language
    case genre
    case category
    case privacy
}

// MARK: - ClubMember (ER: CLUB_MEMBERS table)
struct ClubMember: Codable, Identifiable {
    var id: String { "\(clubId ?? "")_\(userId)" }  // derived
    let clubId: String?                          // FK → Club.id (optional when embedded)
    let userId: String                           // FK → User.id
    let role: String?
    let joinedAt: String?
    var fullName: String?                        // Cache name for display

    enum CodingKeys: String, CodingKey {
        case clubId = "club_id"
        case userId = "user_id"
        case role
        case joinedAt = "joined_at"
        case fullName = "full_name"
    }
}

// MARK: - ChatRoomMessage
struct ChatRoomMessage: Codable {
    let userId: String         // FK → User.id (for future profile navigation)
    let name: String
    let text: String
    let time: String
    var isMine: Bool           // true = sent by current user
    var avatarUrl: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case name, text, time, isMine
        case avatarUrl = "avatar_url"
    }
}

// MARK: - ChatRoom
struct ChatRoom: Codable, Identifiable {
    let id: String
    var clubId: String?        // FK → Club.id
    let title: String
    let icon: String
    var messages: [ChatRoomMessage]?

    enum CodingKeys: String, CodingKey {
        case id
        case clubId = "club_id"
        case title, icon, messages
    }
}

// MARK: - Discussion (ER: DISCUSSIONS table)// schedule discussion
struct Discussion: Codable, Identifiable {
    let id: String
    let clubId: String?          // FK → Club.id
    let createdBy: String        // FK → User.id
    let title: String
    let description: String?
    let date: String?
    let time: String?
    let meetingLink: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case clubId = "club_id"
        case createdBy
        case title, description, date, time
        case meetingLink = "meeting_link"
        case createdAt = "created_at"
    }
}

struct Filter: Codable {
    let title: String
    var isSelected: Bool
}

// MARK: - DiscussionPost / Post (ER: POSTS table)
struct DiscussionPost: Codable, Identifiable {
    let id: String
    let userId: String?          // FK → User.id
    let title: String
    let content: String
    let authorName: String
    let postType: String?
    let createdAt: String
    var upvotes: Int?
    var commentCount: Int?
    var comments: [Comment]?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title, content, authorName
        case postType = "post_type"
        case createdAt
        case upvotes
        case commentCount = "comment_count"
        case comments
    }
}

// MARK: - Comment (ER: COMMENTS table)
struct Comment: Codable, Identifiable {
    let id: String               // comment_id
    let postId: String           // FK → Post.id
    let userId: String           // FK → User.id
    let content: String
    var authorName: String?      // display name for UI
    var createdAt: String?       // time string for UI
    var upvotes: Int?            // vote count for UI

    enum CodingKeys: String, CodingKey {
        case id = "comment_id"
        case postId = "post_id"
        case userId = "user_id"
        case content
        case authorName
        case createdAt
        case upvotes
    }
}

// MARK: - Tag (ER: TAGS table)
struct Tag: Codable, Identifiable {
    let id: String               // tag_id
    let name: String

    enum CodingKeys: String, CodingKey {
        case id = "tag_id"
        case name
    }
}

// MARK: - PostTag (ER: POST_TAGS join table)
struct PostTag: Codable {
    let postId: String
    let tagId: String

    enum CodingKeys: String, CodingKey {
        case postId = "post_id"
        case tagId = "tag_id"
    }
}

// MARK: - PostLike (ER: POST_LIKES join table)
struct PostLike: Codable {
    let postId: String
    let userId: String

    enum CodingKeys: String, CodingKey {
        case postId = "post_id"
        case userId = "user_id"
    }
}


// MARK: - ClubDetail (Composite view model)
struct ClubDetail: Codable {
    var club: Club?
    let members: [String]?
    let admins: [String]
    let coAdmins: [String]?
    var chatRooms: [ChatRoom]
    var upcomingDiscussions: [Discussion]
    let posts: [DiscussionPost]
    let filters: [Filter]
}
