import Foundation

// MARK: - Club Category Enum
enum ClubCategory: String, CaseIterable, Codable {
    case dark
    case poetry
    case classics
    case philosophy
    case fantasy
}

// MARK: - Club Section Enum
enum ClubSection: String, CaseIterable, Codable {
    case myClubs = "my_clubs"
    case recommended
    case trending
}

struct ClubMember: Codable, Identifiable {
    var id: String { "\(clubId ?? "")_\(userId)" }
    let clubId: String?
    let userId: String
    let role: String?
    let joinedAt: String?

    enum CodingKeys: String, CodingKey {
        case clubId = "club_id"
        case userId = "user_id"
        case role
        case joinedAt = "joined_at"
    }
}

struct Club: Codable, Identifiable {
    let id: String?
    let name: String?
    let category: ClubCategory?
    let description: String?
    let imagePath: String?
    let memberCount: Int?
    let language: String?
    var members: [ClubMember]?
    let section: ClubSection?
    var createdBy: String?
    let visibility: String?

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

struct ClubsResponse: Codable {
    let clubs: [Club]
    
    // Ignoring the other root keys like total_count for this test
    enum CodingKeys: String, CodingKey {
        case clubs
    }
}

let url = URL(fileURLWithPath: "Club/Model/clubs.json")
do {
    let data = try Data(contentsOf: url)
    let decoder = JSONDecoder()
    let response = try decoder.decode(ClubsResponse.self, from: data)
    print("✅ clubs.json decoded successfully! count: \(response.clubs.count)")
} catch {
    print("❌ clubs.json decoding error: \(error)")
}

// ------

struct ChatRoomMessage: Codable {
    let userId: String
    let name: String
    let text: String
    let time: String
    let isMine: Bool

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case name, text, time, isMine
    }
}

struct ChatRoom: Codable, Identifiable {
    let id: String
    let clubId: String?
    let title: String
    let icon: String
    var messages: [ChatRoomMessage]?

    enum CodingKeys: String, CodingKey {
        case id
        case clubId = "club_id"
        case title, icon, messages
    }
}

struct Discussion: Codable, Identifiable {
    let id: String
    let clubId: String?
    let createdBy: String
    let title: String
    let description: String?
    let date: String?
    let time: String?
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case clubId = "club_id"
        case createdBy
        case title, description, date, time
        case createdAt = "created_at"
    }
}

struct Filter: Codable {
    let title: String
    var isSelected: Bool
}

struct DiscussionPost: Codable, Identifiable {
    let id: String
    let userId: String?
    let title: String
    let content: String
    let authorName: String
    let postType: String?
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title, content, authorName
        case postType = "post_type"
        case createdAt
    }
}

struct ClubDetail: Codable {
    var club: Club?
    let members: [String]?
    let admins: [String]
    let coAdmins: [String]?
    let chatRooms: [ChatRoom]
    let upcomingDiscussions: [Discussion]
    let posts: [DiscussionPost]
    let filters: [Filter]
}

struct ClubDetailResponse: Codable {
    let clubDetails: [String: ClubDetail]
}

let url2 = URL(fileURLWithPath: "Club/Model/clubDetail.json")
do {
    let data = try Data(contentsOf: url2)
    let decoder = JSONDecoder()
    let response = try decoder.decode(ClubDetailResponse.self, from: data)
    print("✅ clubDetail.json decoded successfully! count: \(response.clubDetails.count)")
} catch {
    print("❌ clubDetail.json decoding error: \(error)")
}
