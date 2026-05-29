//
//  ProfileData.swift
//  Club
//
//  Created by Manas  on 16/03/26.
//
import Foundation

// MARK: - Main Response (Legacy)
class ProfileData: Codable {

    // key = user id
    var profiles: [String: Profile] = [:]

    init() {
        do {
            let response = try load()
            profiles = response.profiles
        } catch {
            print("init decoding error:", error)
        }
    }
    

    // MARK: - Public Access
    func detail(for id: String) -> Profile? {
        return profiles[id]
    }
}


// MARK: - JSON Loading Helper (Legacy)
extension ProfileData {

    func load(from filename: String = "profile") throws -> ProfileData {

        guard let url = Bundle.main.url(
            forResource: filename,
            withExtension: "json"
        ) else {
            throw NSError(
                domain: "ProfileData",
                code: 404,
                userInfo: [
                    NSLocalizedDescriptionKey: "profile.json not found"
                ]
            )
        }

        let data = try Data(contentsOf: url)

        let decoder = JSONDecoder()

        return try decoder.decode(ProfileData.self, from: data)
    }

    func decode(from data: Data) throws -> ProfileData {
        let decoder = JSONDecoder()
        return try decoder.decode(ProfileData.self, from: data)
    }
}

// MARK: - Profile Screen Response (New)
struct ProfileScreenData: Codable {
    var profile: Profile?
    var posts: [Post]?
    var profiles: [String: Profile]?
}

class ProfileScreenModel {
    var data: ProfileScreenData?
    
    init() {
        loadData()
    }
    
    private func loadData() {
        guard let url = Bundle.main.url(forResource: "profile", withExtension: "json") else {
            print("profile.json not found in Bundle, failing gracefully.")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601 
            self.data = try decoder.decode(ProfileScreenData.self, from: data)
        } catch {
            print("ProfileScreenData decoding error: \(error), failing gracefully.")
        }
    }
}
