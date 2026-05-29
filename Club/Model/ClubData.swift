import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

class ClubsData {
    var allClubs: [Club] = []
    private var listener: ListenerRegistration?
    private var followingList: [String] = []

    init() {}

    func fetchClubs(completion: @escaping () -> Void) {
        listener?.remove()
        let db = Firestore.firestore()
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }

        // 1. Listen to current user's following list for recommendations
        db.collection("profiles").document(currentUserId).addSnapshotListener { [weak self] snapshot, _ in
            self?.followingList = snapshot?.data()?["following"] as? [String] ?? []
        }

        // 2. Listen to all clubs
        listener = db.collection("clubs").addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            if let error = error {
                print("❌ Firebase fetch failed for clubs: \(error)")
                return
            }
            
            let fetchedClubs = snapshot?.documents.compactMap { try? $0.data(as: Club.self) } ?? []
            
            if fetchedClubs.isEmpty {
                print("ℹ️ No clubs found. Seeding sample clubs...")
                self.seedClubs()
            }
            
            self.allClubs = fetchedClubs
            completion()
        }
    }

    private func seedClubs() {
        let sampleClubs = [
            Club(id: UUID().uuidString, name: "Kafka Circle", category: .classics, description: "Discussing the works of Franz Kafka.", imagePath: "https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?q=80&w=1000", memberCount: 120, language: "English", members: [], section: .recommended, createdBy: "system", visibility: "public"),
            Club(id: UUID().uuidString, name: "Poetry Night", category: .poetry, description: "Share your latest poems and lyrics.", imagePath: "https://images.unsplash.com/photo-1512446816042-444d641267d4?q=80&w=1000", memberCount: 85, language: "English", members: [], section: .trending, createdBy: "system", visibility: "public"),
            Club(id: UUID().uuidString, name: "Dark Academia", category: .dark, description: "For lovers of mystery and gothic literature.", imagePath: "https://images.unsplash.com/photo-1516979187457-637abb4f9353?q=80&w=1000", memberCount: 210, language: "English", members: [], section: .recommended, createdBy: "system", visibility: "public")
        ]
        
        for club in sampleClubs {
            saveClubToFirebase(club)
        }
    }

    func getRandomClub() -> Club? {
        return allClubs.randomElement()
    }

    func clubs(for section: ClubSection) -> [Club] {
        if section == .myClubs {
            return allClubs.filter { isUserMember($0) }
        } else if section == .recommended {
            // Recommendation Logic:
            // 1. Clubs you are NOT in
            // 2. Has a friend (someone you follow) in it OR created by friend
            var recommended = allClubs.filter { club in
                guard !isUserMember(club) else { return false }
                
                let hasFriend = club.members?.contains(where: { followingList.contains($0.userId) }) ?? false
                let createdByFriend = followingList.contains(club.createdBy ?? "")
                
                return hasFriend || createdByFriend
            }
            
            // Fallback: If no friend recommendations, recommend based on bookshelf
            if recommended.isEmpty {
                let myBooks = AppDependencies.shared.bookshelfData.allBooks
                if !myBooks.isEmpty {
                    recommended = allClubs.filter { club in
                        guard !isUserMember(club) else { return false }
                        // Check if club category or description matches any book author/title
                        return myBooks.contains { book in
                            let titleMatch = club.name?.lowercased().contains(book.title.lowercased()) ?? false
                            let catMatch = club.category?.rawValue.lowercased() == book.title.lowercased()
                            let descMatch = club.description?.lowercased().contains(book.title.lowercased()) ?? false
                            return titleMatch || catMatch || descMatch
                        }
                    }
                }
            }
            
            // Final fallback: System recommended clubs or just random
            if recommended.isEmpty {
                recommended = allClubs.filter { !isUserMember($0) && $0.section == .recommended }
                if recommended.isEmpty {
                    recommended = Array(allClubs.filter { !isUserMember($0) }.shuffled().prefix(3))
                }
            }
            return recommended
        } else {
            return allClubs.filter { $0.section == section && !isUserMember($0) }
        }
    }
    
    func addClub(_ club: Club) {
        allClubs.insert(club, at: 0)
    }
    
    // MARK: - Club Actions
    
    func joinClub(clubId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        Task {
            do {
                let db = Firestore.firestore()
                
                // 1. Check if already a member
                let clubDoc = try await db.collection("clubs").document(clubId).getDocument()
                guard let club = try? clubDoc.data(as: Club.self) else { return }
                
                if club.members?.contains(where: { $0.userId == currentUserId }) == true {
                    print("ℹ️ User already in club. Skipping join.")
                    return
                }
                
                // 2. Fetch user's name from their profile first
                let profileDoc = try await db.collection("profiles").document(currentUserId).getDocument()
                let fullName = profileDoc.data()?["fullName"] as? String ?? "User"
                
                // 2. Create membership with the name
                let newMember = ClubMember(
                    clubId: clubId,
                    userId: currentUserId,
                    role: "member",
                    joinedAt: "\(Date())",
                    fullName: fullName
                )
                
                let encoder = Firestore.Encoder()
                let memberData = try encoder.encode(newMember)
                
                try await db.collection("clubs").document(clubId).updateData([
                    "members": FieldValue.arrayUnion([memberData])
                ])
                print("✅ Successfully joined club as \(fullName)")
            } catch {
                print("❌ Failed to join club: \(error)")
            }
        }
    }
    
    func leaveClub(clubId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        Task {
            do {
                let doc = try await Firestore.firestore().collection("clubs").document(clubId).getDocument()
                guard let club = try? doc.data(as: Club.self), var members = club.members else { return }
                
                members.removeAll { $0.userId == currentUserId }
                
                let encoder = Firestore.Encoder()
                let membersData = try members.map { try encoder.encode($0) }
                
                try await Firestore.firestore().collection("clubs").document(clubId).updateData([
                    "members": membersData
                ])
                print("✅ Successfully left club")
            } catch {
                print("❌ Failed to leave club: \(error)")
            }
        }
    }
    
    func deleteClub(clubId: String) {
        Task {
            do {
                try await Firestore.firestore().collection("clubs").document(clubId).delete()
                print("✅ Successfully deleted club")
            } catch {
                print("❌ Failed to delete club: \(error)")
            }
        }
    }

    func removeMember(clubId: String, userId: String) {
        Task {
            do {
                let doc = try await Firestore.firestore().collection("clubs").document(clubId).getDocument()
                guard let club = try? doc.data(as: Club.self), var members = club.members else { return }
                
                members.removeAll { $0.userId == userId }
                
                let encoder = Firestore.Encoder()
                let membersData = try members.map { try encoder.encode($0) }
                
                try await Firestore.firestore().collection("clubs").document(clubId).updateData([
                    "members": membersData
                ])
                print("✅ Successfully removed member")
            } catch {
                print("❌ Failed to remove member: \(error)")
            }
        }
    }

    func saveClubToFirebase(_ club: Club) {
        var clubToSave = club
        let currentUserId = Auth.auth().currentUser?.uid ?? ""
        
        if clubToSave.createdBy == nil {
            clubToSave.createdBy = currentUserId
        }
        
        Task {
            do {
                // 1. Fetch creator's name from profile
                let profileDoc = try await Firestore.firestore().collection("profiles").document(currentUserId).getDocument()
                let fullName = profileDoc.data()?["fullName"] as? String ?? "User"
                
                // 2. Update the creator member with their real name
                if var members = clubToSave.members, !members.isEmpty {
                    members[0].fullName = fullName
                    clubToSave.members = members
                }
                
                // 3. Upload image if present
                if let image = clubToSave.localImage {
                    let path = "club_images/\(UUID().uuidString).jpg"
                    let imageUrl = try await FirebaseManager.shared.uploadImage(image: image, path: path)
                    clubToSave.imagePath = imageUrl
                }
                
                try await FirebaseManager.shared.insert(collection: "clubs", item: clubToSave)
                print("✅ Successfully saved club and auto-joined as \(fullName)")
            } catch {
                print("❌ Failed to save club to Firebase: \(error)")
            }
        }
    }
}

extension ClubsData {
    func isUserMember(_ club: Club) -> Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return false }
        return club.members?.contains(where: { $0.userId == currentUserId }) ?? false
    }
}
