import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import UIKit

class FirebaseManager {
    static let shared = FirebaseManager()
    let db = Firestore.firestore()
    let auth = Auth.auth()
    let storage = Storage.storage()

    private init() {}

    func requireAuth(completion: @escaping (Bool) -> Void) {
        if let _ = auth.currentUser {
            completion(true)
        } else {
            completion(false)
        }
    }

    func signUp(email: String, password: String) async throws {
        try await auth.createUser(withEmail: email, password: password)
    }

    func signIn(email: String, password: String) async throws {
        try await auth.signIn(withEmail: email, password: password)
    }
    
    func signOut() throws {
        try auth.signOut()
    }

    func insert<T: Encodable>(collection: String, item: T) async throws {
        let encoder = Firestore.Encoder()
        let data = try encoder.encode(item)
        
        if let idString = data["id"] as? String {
            try await db.collection(collection).document(idString).setData(data)
        } else if let idString = data["user_id"] as? String {
            try await db.collection(collection).document(idString).setData(data)
        } else {
            try await db.collection(collection).addDocument(data: data)
        }
    }

    func uploadImage(image: UIImage, path: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "ImageError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not compress image"])
        }
        
        let storageRef = storage.reference().child(path)
        let _ = try await storageRef.putDataAsync(imageData)
        let downloadURL = try await storageRef.downloadURL()
        return downloadURL.absoluteString
    }
}
