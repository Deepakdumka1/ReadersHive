import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

enum FollowType {
    case followers
    case following
}

class FollowRepository {
    static let shared = FollowRepository()
    private let db = Firestore.firestore()
    
    private var followingProfiles: [Profile] = []
    private var followersProfiles: [Profile] = []
    
    // Raw IDs
    var followingIds: [String] = []
    var followersIds: [String] = []
    
    private var listener: ListenerRegistration?
    
    init() {
        startListening()
    }
    
    func startListening() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        listener?.remove()
        listener = db.collection("profiles").document(currentUserId).addSnapshotListener { [weak self] snapshot, _ in
            guard let self = self else { return }
            let data = snapshot?.data()
            let followingIds = data?["following"] as? [String] ?? []
            let followersIds = data?["followers"] as? [String] ?? []
            
            self.followingIds = followingIds
            self.followersIds = followersIds
            
            // Fetch profiles for these IDs
            self.fetchProfiles(ids: followingIds) { profiles in
                self.followingProfiles = profiles
            }
            
            self.fetchProfiles(ids: followersIds) { profiles in
                self.followersProfiles = profiles
            }
        }
    }
    
    private func fetchProfiles(ids: [String], completion: @escaping ([Profile]) -> Void) {
        guard !ids.isEmpty else {
            completion([])
            return
        }
        
        // Firestore 'in' query supports up to 10 IDs. For more, we'd need to batch.
        // For now, let's just fetch the first 10 for the quick search logic.
        let queryIds = Array(ids.prefix(10))
        
        db.collection("profiles").whereField(FieldPath.documentID(), in: queryIds).getDocuments { snapshot, _ in
            let profiles = snapshot?.documents.compactMap { try? $0.data(as: Profile.self) } ?? []
            completion(profiles)
        }
    }
    
    func followers(for userId: String) -> [Profile] {
        return followersProfiles
    }
    
    func following(for userId: String) -> [Profile] {
        return followingProfiles
    }
    
    func toggleFollow(currentUserId: String, targetUserId: String) {
        Task {
            do {
                let currentUserRef = db.collection("profiles").document(currentUserId)
                let targetUserRef = db.collection("profiles").document(targetUserId)
                
                let snapshot = try await currentUserRef.getDocument()
                let data = snapshot.data()
                let following = data?["following"] as? [String] ?? []
                let isFollowing = following.contains(targetUserId)
                
                if isFollowing {
                    try await currentUserRef.updateData(["following": FieldValue.arrayRemove([targetUserId])])
                    try await targetUserRef.updateData(["followers": FieldValue.arrayRemove([currentUserId])])
                } else {
                    try await currentUserRef.updateData(["following": FieldValue.arrayUnion([targetUserId])])
                    try await targetUserRef.updateData(["followers": FieldValue.arrayUnion([currentUserId])])
                }
            } catch {
                print("❌ Failed to toggle follow: \(error)")
            }
        }
    }
}
