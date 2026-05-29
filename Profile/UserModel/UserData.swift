import Foundation

// MARK: - Main Response
class UserData: Codable {

    // key = user id
    var users: [String: User] = [:]

    init() {
        do {
            let response = try load()
            users = response.users
        } catch {
            print("init decoding error:", error)
        }
    }

    // MARK: - Public Access
    func detail(for id: String) -> User? {
        return users[id]
    }
}

// MARK: - JSON Loading Helper
extension UserData {

    func load(from filename: String = "user") throws -> UserData {

        guard let url = Bundle.main.url(
            forResource: filename,
            withExtension: "json"
        ) else {
            throw NSError(
                domain: "UserData",
                code: 404,
                userInfo: [
                    NSLocalizedDescriptionKey: "user.json not found"
                ]
            )
        }

        let data = try Data(contentsOf: url)

        let decoder = JSONDecoder()

        return try decoder.decode(UserData.self, from: data)
    }

    func decode(from data: Data) throws -> UserData {
        let decoder = JSONDecoder()
        return try decoder.decode(UserData.self, from: data)
    }
}
