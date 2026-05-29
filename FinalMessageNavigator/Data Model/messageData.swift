import Foundation
import FirebaseFirestore
import FirebaseAuth

class MessageDataModel {
    
    private var conversationList: [Conversation] = []
    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()
    
    init() {
        listenForConversations()
    }
    
    func getConversations() -> [Conversation] {
        return conversationList
    }
    
    func listenForConversations(completion: (() -> Void)? = nil) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { 
            completion?()
            return 
        }
        
        listener?.remove()
        listener = db.collection("conversations")
            .whereField("participants", arrayContains: currentUserId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Conversation listener error: \(error)")
                    completion?()
                    return
                }
                
                let documents = snapshot?.documents ?? []
                let group = DispatchGroup()
                var updatedConversations: [Conversation] = []
                
                for doc in documents {
                    let data = doc.data()
                    let id = doc.documentID
                    let participants = data["participants"] as? [String] ?? []
                    let otherUserId = participants.first { $0 != currentUserId } ?? ""
                    
                    group.enter()
                    // Fetch the other user's profile to get current name and avatar
                    self.db.collection("profiles").document(otherUserId).getDocument { profileSnapshot, _ in
                        let profileData = profileSnapshot?.data()
                        let name = profileData?["fullName"] as? String ?? "User"
                        let avatar = profileData?["avatarUrl"] as? String ?? ""
                        
                        let conversation = Conversation(
                            id: id,
                            otherUserId: otherUserId,
                            otherUserName: name,
                            avatarImage: avatar,
                            lastMessage: data["last_message"] as? String ?? "",
                            lastMessageTimestamp: (data["last_message_timestamp"] as? Timestamp)?.dateValue()
                        )
                        
                        updatedConversations.append(conversation)
                        group.leave()
                    }
                }
                
                group.notify(queue: .main) {
                    self.conversationList = updatedConversations.sorted { 
                        ($0.lastMessageTimestamp ?? Date.distantPast) > ($1.lastMessageTimestamp ?? Date.distantPast)
                    }
                    NotificationCenter.default.post(name: NSNotification.Name("conversationsUpdated"), object: nil)
                    completion?()
                }
                
                if documents.isEmpty {
                    self.conversationList = []
                    NotificationCenter.default.post(name: NSNotification.Name("conversationsUpdated"), object: nil)
                    completion?()
                }
            }
    }
    
    func startConversation(with otherUser: Profile, completion: @escaping (String) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let conversationId = [currentUserId, otherUser.userId].sorted().joined(separator: "_")
        let docRef = db.collection("conversations").document(conversationId)
        
        docRef.setData([
            "participants": [currentUserId, otherUser.userId],
            "last_message": "Tap to chat",
            "last_message_timestamp": FieldValue.serverTimestamp()
        ], merge: true) { _ in
            completion(conversationId)
        }
    }
}
