import Foundation

class SettingsManager {
    static let shared = SettingsManager()
    
    private let defaults = UserDefaults.standard
    
    private init() {}
    
    var isPrivateAccount: Bool {
        get { defaults.bool(forKey: "isPrivateAccount") }
        set { defaults.set(newValue, forKey: "isPrivateAccount") }
    }
    
    enum MessagePermissions: String {
        case everyone = "Everyone"
        case followersOnly = "Followers only"
    }
    
    var messagePermissions: MessagePermissions {
        get {
            if let value = defaults.string(forKey: "messagePermissions"),
               let permission = MessagePermissions(rawValue: value) {
                return permission
            }
            return .everyone
        }
        set {
            defaults.set(newValue.rawValue, forKey: "messagePermissions")
        }
    }
    
    var activityVisibility: Bool {
        get { return defaults.object(forKey: "activityVisibility") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "activityVisibility") }
    }
    
    func logout() {
        // Clear session mock
        print("SettingsManager: Logged out.")
    }
}
