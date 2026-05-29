import Foundation

enum SettingsSection: Int, CaseIterable {
    case account
    case privacy
    case accountActions
    
    var title: String? {
        switch self {
        case .account: return "Account"
        case .privacy: return "Privacy"
        case .accountActions: return "Account Actions"
        }
    }
    
    var rows: [SettingsRow] {
        switch self {
        case .account:
            return [.editProfile, .changePassword]
        case .privacy:
            return [.privateAccount, .messagePermissions, .activityVisibility]
        case .accountActions:
            return [.logout]
        }
    }
}

enum SettingsRow {
    // Account
    case editProfile
    case changePassword
    
    // Privacy
    case privateAccount
    case messagePermissions
    case activityVisibility
    
    // Account Actions
    case logout
    
    var title: String {
        switch self {
        case .editProfile: return "Edit Profile"
        case .changePassword: return "Change Password"
        case .privateAccount: return "Private Account"
        case .messagePermissions: return "Message Permissions"
        case .activityVisibility: return "Activity Visibility"
        case .logout: return "Logout"
        }
    }
}
