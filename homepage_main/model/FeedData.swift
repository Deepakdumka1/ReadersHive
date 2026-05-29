import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

final class FeedData {
    private(set) var posts: [FeedPost] = []
    private var listener: ListenerRegistration?

    init() {
        load()
    }

    private var profileListener: ListenerRegistration?
    private var followingIds: [String] = []

    func load(completion: (([FeedPost]) -> Void)? = nil) {
        listener?.remove()
        profileListener?.remove()
        
        let db = Firestore.firestore()
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // 1. Live listener for YOUR following list
        profileListener = db.collection("profiles").document(currentUserId).addSnapshotListener { [weak self] snapshot, _ in
            guard let self = self else { return }
            self.followingIds = snapshot?.data()?["following"] as? [String] ?? []
            self.refreshFeed(completion: completion)
        }

        // 2. Live listener for ALL posts
        listener = db.collection("posts")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] _, _ in
                guard let self = self else { return }
                self.refreshFeed(completion: completion)
            }
    }

    private func refreshFeed(completion: (([FeedPost]) -> Void)? = nil) {
        let db = Firestore.firestore()
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("posts")
            .order(by: "createdAt", descending: true)
            .getDocuments { [weak self] snapshot, _ in
                guard let self = self else { return }
                
                var allPosts = snapshot?.documents.compactMap { try? $0.data(as: FeedPost.self) } ?? []
                let allowedIds = [currentUserId] + self.followingIds
                
                // Filter first
                allPosts = allPosts.filter { post in
                    guard let uid = post.userId else { return false }
                    return allowedIds.contains(uid)
                }
                
                // Join with profiles to get latest avatars
                Task {
                    var updatedPosts: [FeedPost] = []
                    for var post in allPosts {
                        if let uid = post.userId {
                            if let profileDoc = try? await db.collection("profiles").document(uid).getDocument(),
                               let profile = try? profileDoc.data(as: Profile.self) {
                                post.avatarUrl = profile.avatarUrl
                                post.name = profile.fullName // also get latest name
                            }
                        }
                        updatedPosts.append(post)
                    }
                    
                    DispatchQueue.main.async {
                        self.posts = updatedPosts
                        completion?(updatedPosts)
                    }
                }
            }
    }
    
    private func fetchWithoutSorting(completion: (([FeedPost]) -> Void)?) {
        Firestore.firestore().collection("posts").getDocuments { snapshot, error in
            let fetchedPosts = snapshot?.documents.compactMap { try? $0.data(as: FeedPost.self) } ?? []
            DispatchQueue.main.async {
                self.posts = fetchedPosts
                completion?(self.posts)
            }
        }
    }

    func savePost(_ post: FeedPost) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        var postToSave = post
        postToSave.userId = currentUserId
        postToSave.createdAt = Date()
        
        Task {
            // Fetch current user's profile to get their real name
            if let profileDoc = try? await Firestore.firestore().collection("profiles").document(currentUserId).getDocument(),
               let profile = try? profileDoc.data(as: Profile.self) {
                postToSave.name = profile.fullName
            }
            
            if let image = postToSave.localImage {
                do {
                    let path = "post_images/\(UUID().uuidString).jpg"
                    let imageUrl = try await FirebaseManager.shared.uploadImage(image: image, path: path)
                    postToSave.postImage = imageUrl
                } catch {
                    print("❌ Image upload failed: \(error)")
                }
            }
            
            do {
                try await FirebaseManager.shared.insert(collection: "posts", item: postToSave)
                print("✅ Post saved to Firebase successfully")
            } catch {
                print("❌ Failed to save post to Firebase: \(error)")
            }
        }
    }

    private func seedTestData() {
        let testPost = FeedPost(
            id: UUID().uuidString,
            userId: "system",
            name: "ReadersHive Team",
            time: "Just now",
            title: "Welcome!",
            content: "Welcome to the new Firebase-powered ReadersHive! Your data is now live and syncing in real-time.",
            likeCount: 5,
            commentCount: 2,
            isLiked: false,
            createdAt: Date()
        )
        
        Task {
            try? await FirebaseManager.shared.insert(collection: "posts", item: testPost)
        }
    }

    func toggleLike(for postId: String) {
        guard let index = posts.firstIndex(where: { $0.id == postId }) else { return }
        var post = posts[index]
        let currentlyLiked = post.isLiked
        post.isLiked = !currentlyLiked
        if !currentlyLiked {
            post.likeCount += 1
        } else {
            post.likeCount = max(0, post.likeCount - 1)
        }
        posts[index] = post
        
        let docRef = Firestore.firestore().collection("posts").document(postId)
        docRef.updateData([
            "likeCount": post.likeCount,
            "isLiked": post.isLiked
        ])
    }
    
    // MARK: - Comments
    func fetchComments(for postId: String, completion: @escaping ([PostComment]) -> Void) -> ListenerRegistration {
        return Firestore.firestore().collection("posts").document(postId).collection("comments")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { snapshot, error in
                let comments = snapshot?.documents.compactMap { try? $0.data(as: PostComment.self) } ?? []
                DispatchQueue.main.async {
                    completion(comments)
                }
            }
    }
    
    func addComment(to postId: String, content: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        Task {
            // Fetch profile
            var userName = "User"
            var avatarUrl: String? = nil
            if let profileDoc = try? await db.collection("profiles").document(currentUserId).getDocument(),
               let profile = try? profileDoc.data(as: Profile.self) {
                userName = profile.fullName
                avatarUrl = profile.avatarUrl
            }
            
            let newComment = PostComment(
                id: UUID().uuidString,
                postId: postId,
                userId: currentUserId,
                userName: userName,
                userAvatarUrl: avatarUrl,
                content: content,
                createdAt: Date()
            )
            
            do {
                try db.collection("posts").document(postId).collection("comments").document(newComment.id).setData(from: newComment)
                
                // Increment comment count
                try await db.collection("posts").document(postId).updateData([
                    "commentCount": FieldValue.increment(Int64(1))
                ])
                print("✅ Comment added")
            } catch {
                print("❌ Failed to add comment: \(error)")
            }
        }
    }
}
