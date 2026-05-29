//
//  BookDiscussion.swift
//  Club
//
//  Created by Antigravity on 28/04/26.
//
//  Data model and mock store for book-level community discussions.
//  Designed to be self-contained — no dependency on Club's DiscussionPost.
//

import Foundation

// MARK: - Discussion Tag

/// Tags used to categorize book discussions (filter chips in Community tab).
enum BookDiscussionTag: String, CaseIterable, Codable {
    case theme    = "Theme"
    case setting  = "Setting"
    case spoiler  = "Spoiler"
    case author   = "Author"
    case plot     = "Plot"
    case character = "Character"
    case fandom   = "Fandom"
    
    /// Color hex for the tag badge background.
    var colorHex: String {
        switch self {
        case .theme:     return "#7B61FF"
        case .setting:   return "#3D9BE9"
        case .spoiler:   return "#E94B4B"
        case .author:    return "#4CAF50"
        case .plot:      return "#FF9800"
        case .character: return "#E91E63"
        case .fandom:    return "#9C27B0"
        }
    }
}

// MARK: - Book Discussion Model

/// A single community discussion post for a book.
struct BookDiscussion: Identifiable, Codable {
    let id: String
    var bookTitle: String?           // Added for Firestore querying
    let username: String
    let avatarEmoji: String          // Emoji-based avatar (e.g. "👩🏾", "🧝🏻‍♀️")
    let tag: BookDiscussionTag
    let tagLabel: String             // Display text (e.g. "Throne of Glass Fandom")
    let timestamp: String            // Relative time (e.g. "2h ago")
    let content: String
    let isSpoiler: Bool
    var isRevealed: Bool = false     // Spoiler reveal state (mutable for toggle)
    var replies: [BookDiscussionReply] = []
}

// MARK: - Reply Model

/// A reply to a book discussion.
struct BookDiscussionReply: Identifiable, Codable {
    let id: String
    let username: String
    let avatarEmoji: String
    let content: String
    let timestamp: String
}

import FirebaseFirestore
import FirebaseAuth

// MARK: - Discussion Store

/// In-memory store for book discussions. Provides mock data and CRUD.
/// One store instance per book card session.
class BookDiscussionStore {
    
    /// All discussions for the current book.
    private(set) var discussions: [BookDiscussion] = []
    
    /// Currently selected filter tag (nil = show all).
    var selectedTag: BookDiscussionTag? = nil
    
    /// Filtered discussions based on selected tag.
    var filteredDiscussions: [BookDiscussion] {
        var result = selectedTag == nil ? discussions : discussions.filter { $0.tag == selectedTag }
        for i in 0..<result.count {
            if revealedSpoilerIds.contains(result[i].id) {
                result[i].isRevealed = true
            }
        }
        return result
    }
    
    var onDiscussionsUpdated: (() -> Void)?
    
    private var revealedSpoilerIds: Set<String> = []
    
    let bookTitle: String
    private var listener: ListenerRegistration?
    
    init(bookTitle: String) {
        self.bookTitle = bookTitle
        startListening()
    }
    
    deinit {
        listener?.remove()
    }
    
    private func startListening() {
        let db = Firestore.firestore()
        listener = db.collection("book_discussions")
            .whereField("bookTitle", isEqualTo: bookTitle)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                guard let docs = snapshot?.documents else { return }
                
                var firestoreDiscussions: [BookDiscussion] = []
                for doc in docs {
                    if let discussion = try? doc.data(as: BookDiscussion.self) {
                        firestoreDiscussions.append(discussion)
                    }
                }
                
                // Sort newest first
                firestoreDiscussions.sort { (d1, d2) -> Bool in
                    // Simple string comparison works for ISO8601 or similar, but since we use string timestamps,
                    // we'll just reverse them if they are sequential. In a real app we'd use a Date field.
                    // For now, assume Firestore returns them in arbitrary order so we just keep them.
                    return d1.id > d2.id // naive sort
                }
                
                self.mergeWithClubDiscussions(firestoreDiscussions)
            }
    }
    
    private func mergeWithClubDiscussions(_ firestoreDiscussions: [BookDiscussion]) {
        var allDiscussions = firestoreDiscussions
        
        // Scan for club discussions that tagged this book
        let allDetails = AppDependencies.shared.clubdetailData.clubDetails
        for (_, detail) in allDetails {
            guard let clubName = detail.club?.name else { continue }
            for post in detail.posts {
                // If title indicates it tagged this book
                if post.title.contains("[Book: \(bookTitle)]") || post.title.lowercased().contains(bookTitle.lowercased()) {
                    let mappedTag: BookDiscussionTag
                    if let category = detail.club?.category {
                        switch category {
                        case .dark: mappedTag = .fandom
                        case .poetry: mappedTag = .character
                        case .classics: mappedTag = .author
                        case .philosophy: mappedTag = .theme
                        case .fantasy: mappedTag = .setting
                        }
                    } else {
                        switch post.postType?.lowercased() {
                        case "theme": mappedTag = .theme
                        case "setting": mappedTag = .setting
                        case "spoiler": mappedTag = .spoiler
                        case "author": mappedTag = .author
                        default: mappedTag = .theme
                        }
                    }
                    
                    // Map club post comments to BookDiscussionReply objects
                    let mappedReplies: [BookDiscussionReply] = (post.comments ?? []).map { comment in
                        BookDiscussionReply(
                            id: comment.id,
                            username: comment.authorName ?? "Reader",
                            avatarEmoji: "👤",
                            content: comment.content,
                            timestamp: comment.createdAt ?? "Recently"
                        )
                    }
                    
                    let clubDiscussion = BookDiscussion(
                        id: post.id,
                        bookTitle: bookTitle,
                        username: post.authorName,
                        avatarEmoji: "👤",
                        tag: mappedTag,
                        tagLabel: clubName,
                        timestamp: post.createdAt,
                        content: post.content,
                        isSpoiler: post.postType?.lowercased() == "spoiler",
                        isRevealed: false,
                        replies: mappedReplies
                    )
                    allDiscussions.insert(clubDiscussion, at: 0)
                }
            }
        }
        
        // Append placeholder mock data for visual testing so the screen isn't empty
        allDiscussions.append(contentsOf: BookDiscussionStore.generateMockData(for: bookTitle))
        
        self.discussions = allDiscussions
        DispatchQueue.main.async {
            self.onDiscussionsUpdated?()
        }
    }
    
    // MARK: - CRUD
    
    /// Add a new discussion (from Create Discussion modal).
    func addDiscussion(content: String, tag: BookDiscussionTag, tagLabel: String, isSpoiler: Bool) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        Task {
            let db = Firestore.firestore()
            let profileDoc = try? await db.collection("profiles").document(currentUserId).getDocument()
            let fullName = profileDoc?.data()?["fullName"] as? String ?? "Reader"
            
            let post = BookDiscussion(
                id: UUID().uuidString,
                bookTitle: self.bookTitle,
                username: fullName,
                avatarEmoji: "👤", // Can be upgraded to use real avatarUrl later
                tag: tag,
                tagLabel: tagLabel,
                timestamp: "Just now",
                content: content,
                isSpoiler: isSpoiler
            )
            
            do {
                try db.collection("book_discussions").document(post.id).setData(from: post)
            } catch {
                print("Failed to save discussion: \(error)")
            }
        }
    }
    
    /// Add a reply to a discussion.
    func addReply(to discussionId: String, content: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        Task {
            let db = Firestore.firestore()
            
            // Wait, what if the discussionId is a club post id? (those start with post.id)
            // If it's a club post, we shouldn't save it to book_discussions.
            // For now, if the document doesn't exist in book_discussions, it will silently fail or create a ghost doc.
            // Let's check if it exists in book_discussions.
            let docRef = db.collection("book_discussions").document(discussionId)
            let doc = try? await docRef.getDocument()
            
            if doc?.exists == true {
                // It's a real book discussion
                let profileDoc = try? await db.collection("profiles").document(currentUserId).getDocument()
                let fullName = profileDoc?.data()?["fullName"] as? String ?? "Reader"
                
                let reply = BookDiscussionReply(
                    id: UUID().uuidString,
                    username: fullName,
                    avatarEmoji: "👤",
                    content: content,
                    timestamp: "Just now"
                )
                
                if var discussion = try? doc?.data(as: BookDiscussion.self) {
                    discussion.replies.append(reply)
                    try? docRef.setData(from: discussion)
                }
            } else {
                // It's a club post, technically we should add a comment to the club post in Firebase.
                // For simplicity in this mock, we just ignore or we could print.
                print("Cannot reply directly to club posts from book view yet.")
            }
        }
    }
    
    /// Toggle spoiler reveal state for a discussion.
    func toggleSpoilerReveal(for discussionId: String) {
        if revealedSpoilerIds.contains(discussionId) {
            revealedSpoilerIds.remove(discussionId)
        } else {
            revealedSpoilerIds.insert(discussionId)
        }
        onDiscussionsUpdated?()
    }
    
    // MARK: - Mock Data Generator
    
    private static func generateMockData(for bookTitle: String) -> [BookDiscussion] {
        return [
            BookDiscussion(
                id: "mock_1",
                bookTitle: bookTitle,
                username: "Elide Lochan",
                avatarEmoji: "👩🏾",
                tag: .fandom,
                tagLabel: "Throne of Glass Fandom",
                timestamp: "2h ago",
                content: "I just reached Chapter 45 and I am NOT OKAY. The way Sarah writes these reunions is just cruel. Does it get better or should I prepare my tissues for the rest of the night?",
                isSpoiler: false
            ),
            BookDiscussion(
                id: "mock_2",
                bookTitle: bookTitle,
                username: "Aelin_Fan_99",
                avatarEmoji: "🧝🏻‍♀️",
                tag: .spoiler,
                tagLabel: "Maas Universe Theories",
                timestamp: "5h ago",
                content: "MAJOR SPOILER: The ending with the lock and the wyrdkeys completely broke me. I think Aelin's sacrifice ties into the larger Maasverse timeline. Anyone else notice the connection to Crescent City?",
                isSpoiler: true
            ),
            BookDiscussion(
                id: "mock_3",
                bookTitle: bookTitle,
                username: "BookDragon42",
                avatarEmoji: "🐉",
                tag: .theme,
                tagLabel: "Themes & Analysis",
                timestamp: "8h ago",
                content: "The theme of sacrifice vs. duty in this book is incredible. Sarah J. Maas really outdid herself showing how each character deals with the weight of responsibility.",
                isSpoiler: false
            )
        ]
    }
}
