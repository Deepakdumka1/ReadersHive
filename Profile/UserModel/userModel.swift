//
//  userModel.swift
//  BookHive
//
//  Refactored to match provided ER Diagram and standard Modern Social App Schemas
//

import Foundation

// MARK: - User Model

struct User: Codable, Identifiable, Equatable, Sendable {

    let id: String
    let name: String?
    let email: String?
    
    // Kept to represent ER diagram constraints (often omitted in real client models for security)
    let passwordHash: String? 
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id = "user_id"
        case name, email
        case passwordHash = "password_hash"
        case createdAt = "created_at"
    }
}


// MARK: - Profile Model
struct Profile: Codable, Identifiable, Equatable, Sendable {
    let id: String 

    let userId: String
    let fullName: String
    var username: String
    
    // Core Profile fields mapping to Social concepts and ER Diagram
    var bio: String? 
    var avatarUrl: String?
    var visibility: String
    
    // Extended properties common in social networking apps (and matching older struct)
    var followers: [String]?
    var following: [String]?

    enum CodingKeys: String, CodingKey {
        case id = "profile_id"
        case userId = "user_id"
        case fullName 
        case username
        case bio = "description" 
        case avatarUrl = "avatar_url"
        case visibility
        case followers, following
    }
    
    // Memberwise initializer
    init(id: String, userId: String, fullName: String, username: String, bio: String?, avatarUrl: String?, visibility: String, followers: [String]?, following: [String]?) {
        self.id = id
        self.userId = userId
        self.fullName = fullName
        self.username = username
        self.bio = bio
        self.avatarUrl = avatarUrl
        self.visibility = visibility
        self.followers = followers
        self.following = following
    }
    
    // Custom decoding to handle both avatar_url and avatarUrl keys
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        fullName = try container.decode(String.self, forKey: .fullName)
        username = try container.decode(String.self, forKey: .username)
        bio = try? container.decode(String.self, forKey: .bio)
        visibility = try container.decode(String.self, forKey: .visibility)
        followers = try? container.decode([String].self, forKey: .followers)
        following = try? container.decode([String].self, forKey: .following)
        
        if let url = try? container.decode(String.self, forKey: .avatarUrl) {
            avatarUrl = url
        } else {
            let rawContainer = try decoder.container(keyedBy: RawCodingKeys.self)
            avatarUrl = try? rawContainer.decode(String.self, forKey: .avatarUrlCamel)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(fullName, forKey: .fullName)
        try container.encode(username, forKey: .username)
        try container.encode(bio, forKey: .bio)
        try container.encode(avatarUrl, forKey: .avatarUrl)
        try container.encode(visibility, forKey: .visibility)
        try container.encode(followers, forKey: .followers)
        try container.encode(following, forKey: .following)
    }
    
    private enum RawCodingKeys: String, CodingKey {
        case avatarUrlCamel = "avatarUrl"
    }
    
    // Retro-compatibility mapped properties for old codebase references
    var profileId: String { id }
    var description: String? { 
        get { bio }
        set { bio = newValue }
    }
}

// MARK: - Post Types

enum PostType: String, Codable, Sendable {
    case text, image, video, link
}


// MARK: - Post Model

struct Post: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let userId: String
    var content: String?
    var imageUrl: String?
    var postType: PostType?
    let createdAt: Date
    
    // Rich Hydrated Data Expected in Real Social Networks APIs
    var author: Profile?
    var likesCount: Int?
    var commentsCount: Int?
    var isLikedByCurrentUser: Bool? = false
    var tags: [Tags]?

    enum CodingKeys: String, CodingKey {
        case id = "post_id"
        case userId = "user_id"
        case content
        case imageUrl = "image_url"
        case postType = "post_type"
        case createdAt = "created_at"
        
        // Hydrated fields
        case author
        case likesCount = "likes_count"
        case commentsCount = "comments_count"
        case isLikedByCurrentUser = "is_liked_by_current_user"
        case tags
    }
    
    // Retro-compatibility mapped properties for old codebase references
    var postId: String { id }
    var postTitle: String { 
        get { content ?? "" }
        set { content = newValue }
    }
    var postDescription: String? { 
        get { content }
        set { content = newValue }
    }
}


// MARK: - Comment Model

struct Comments: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let postId: String
    let userId: String
    var content: String
    let createdAt: Date
    
    // Hydrated Data expected in Social Feeds
    var author: Profile?

    enum CodingKeys: String, CodingKey {
        case id = "comment_id"
        case postId = "post_id"
        case userId = "user_id"
        case content
        case createdAt = "created_at"
        
        case author
    }
    
    // Retro-compatibility mapped properties
    var commentID: String { id }
    var postID: String { postId }
    var userID: String { userId }
}


// MARK: - Supporting ER Diagram Models

struct PostLikes: Codable, Equatable, Sendable {
    let postId: String
    let userId: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case postId = "post_id"
        case userId = "user_id"
        case createdAt = "created_at"
    }
}

struct Tags: Codable, Identifiable, Equatable, Sendable {
    let id: String
    var name: String
    
    enum CodingKeys: String, CodingKey {
        case id = "tag_id"
        case name
    }
}




