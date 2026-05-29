//
//  ClubDetailData.swift
//  Club
//

import Foundation

// MARK: - Main Response
class ClubDetailData: Codable {

    // key = club id
    var clubDetails: [String: ClubDetail] = [:]

    init() {
        print("i am here ")
        do {
            let response = try load()
            clubDetails = response.clubDetails
        } catch {
            print("init decoding error", error)
        }
    }

    enum CodingKeys: String, CodingKey {
        case clubDetails
    }

    // MARK: - Public Access

    func detail(for id: String) -> ClubDetail? {
        return clubDetails[id]
    }

    // MARK: - Add Scheduled Discussion (same pattern as ClubsData.addClub)
    func addScheduledDiscussion(_ discussion: Discussion, toClub clubId: String) {
        clubDetails[clubId]?.upcomingDiscussions.insert(discussion, at: 0)
    }
    
    // MARK: - Add ChatRoom
    func addChatRoom(_ chatRoom: ChatRoom, toClub clubId: String) {
        clubDetails[clubId]?.chatRooms.insert(chatRoom, at: 0)
    }
    
    // MARK: - Add DiscussionPost
    func addDiscussionPost(_ post: DiscussionPost, toClub clubId: String) {
        if let detail = clubDetails[clubId] {
            var posts = detail.posts
            posts.insert(post, at: 0)
            clubDetails[clubId] = ClubDetail(
                club: detail.club,
                members: detail.members,
                admins: detail.admins,
                coAdmins: detail.coAdmins,
                chatRooms: detail.chatRooms,
                upcomingDiscussions: detail.upcomingDiscussions,
                posts: posts,
                filters: detail.filters
            )
        }
    }
}

// MARK: - JSON Loading Helper
extension ClubDetailData {

    /// Load club details from JSON file
    func load(from filename: String = "clubDetail") throws -> ClubDetailData {

        guard let url = Bundle.main.url(
            forResource: filename,
            withExtension: "json"
        ) else {
            throw NSError(
                domain: "ClubDetailData",
                code: 404,
                userInfo: [
                    NSLocalizedDescriptionKey: "clubDetail.json not found"
                ]
            )
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()

        print(String(data: data, encoding: .utf8) ?? "")

        do {
            return try decoder.decode(ClubDetailData.self, from: data)
        } catch {
            print("detailed json error", error)
            throw error
        }
    }

    /// Decode directly from Data
    func decode(from data: Data) throws -> ClubDetailData {
        let decoder = JSONDecoder()
        return try decoder.decode(ClubDetailData.self, from: data)
    }
}
