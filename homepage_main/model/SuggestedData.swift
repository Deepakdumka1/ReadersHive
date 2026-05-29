import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

final class SuggestedData {
    private(set) var users: [SuggestedUser] = []
    private var listener: ListenerRegistration?

    init() {
        load()
    }

    private var suggestionsListener: ListenerRegistration?

    func load(completion: (([SuggestedUser]) -> Void)? = nil) {
        listener?.remove()
        suggestionsListener?.remove()
        
        let db = Firestore.firestore()
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // 1. Listen to CURRENT USER's profile to get the accurate following list
        listener = db.collection("profiles").document(currentUserId).addSnapshotListener { [weak self] profileSnapshot, _ in
            guard let self = self else { return }
            let followingList = profileSnapshot?.data()?["following"] as? [String] ?? []
            
            // 2. Real-time listener for OTHER profiles for suggestions
            self.suggestionsListener?.remove()
            self.suggestionsListener = db.collection("profiles")
                .limit(to: 20)
                .addSnapshotListener { [weak self] snapshot, _ in
                    guard let self = self else { return }
                    let profiles = snapshot?.documents.compactMap { try? $0.data(as: Profile.self) } ?? []
                    
                    let mappedUsers = profiles.compactMap { profile -> SuggestedUser? in
                        guard profile.userId != currentUserId else { return nil }
                        let amIFollowing = followingList.contains(profile.userId)
                        
                        return SuggestedUser(
                            id: profile.userId, 
                            username: profile.username,
                            name: profile.fullName,
                            avatarImage: profile.avatarUrl ?? "person.circle.fill",
                            isFollowing: amIFollowing
                        )
                    }
                    
                    DispatchQueue.main.async {
                        self.users = Array(mappedUsers.prefix(10))
                        completion?(self.users)
                    }
                }
        }
    }

    func toggleFollow(for targetUserId: String, completion: ((Bool) -> Void)? = nil) {
        let db = Firestore.firestore()
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }

        guard let index = users.firstIndex(where: { $0.id == targetUserId }) else { return }
        let isNowFollowing = !users[index].isFollowing
        users[index].isFollowing = isNowFollowing
        
        Task {
            do {
                let currentUserRef = db.collection("profiles").document(currentUserId)
                let targetUserRef = db.collection("profiles").document(targetUserId)

                if isNowFollowing {
                    try await currentUserRef.setData(["following": FieldValue.arrayUnion([targetUserId])], merge: true)
                    try await targetUserRef.setData(["followers": FieldValue.arrayUnion([currentUserId])], merge: true)
                } else {
                    try await currentUserRef.setData(["following": FieldValue.arrayRemove([targetUserId])], merge: true)
                    try await targetUserRef.setData(["followers": FieldValue.arrayRemove([currentUserId])], merge: true)
                }
                completion?(true)
            } catch {
                print("❌ Follow failed: \(error)")
                DispatchQueue.main.async {
                    if let i = self.users.firstIndex(where: { $0.id == targetUserId }) {
                        self.users[i].isFollowing.toggle()
                    }
                    completion?(false)
                }
            }
        }
    }
    
    func removeUser(for userId: String) {
        users.removeAll { $0.id == userId }
    }
}
