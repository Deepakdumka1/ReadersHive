# ReadersHive

<p align="center">
  <img src="https://img.shields.io/badge/Status-TestFlight_Ready-blue?style=for-the-badge" alt="Status: TestFlight Ready"/>
  <img src="https://img.shields.io/badge/Platform-iOS-black?style=for-the-badge&logo=apple" alt="Platform: iOS"/>
  <img src="https://img.shields.io/badge/Swift-UIKit-F05138?style=for-the-badge&logo=swift" alt="Swift UIKit"/>
  <img src="https://img.shields.io/badge/Backend-Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase"/>
</p>

> **ReadersHive** is a social reading app for iOS where book lovers discover clubs, build personal bookshelves, schedule discussions, and connect with readers who share their taste — all in one place.

> [!NOTE]
> **🚀 The app is in Beta and ready for TestFlight.** The iOS UI is complete, and the Firebase backend is fully integrated. We are currently finalizing minor refinements and clearing warnings for the final release.

---

## ✨ What is ReadersHive?

ReadersHive is built around one idea: **reading is better together.** The app lets you:

- 📖 **Build your bookshelf** — track books you've read, are reading, or want to read
- 🏛 **Join & discover clubs** — genre-matched clubs for Dark fiction, Poetry, Classics, Philosophy, Fantasy, and more
- 💬 **Discuss & debate** — create posts, upvote discussions, and comment in club spaces
- 📅 **Schedule live discussions** — set meetings with links directly inside a club
- 💬 **Chat in real-time** — dedicated chat rooms per club
- 🔍 **Search users & books** — find books and fellow readers across the platform
- 👤 **Build your profile** — follow readers, showcase your shelf, manage settings

---

## 🗂 Repository Structure

```
Team-K--main/
├── BookHive/                   # Native iOS App (Swift + UIKit)
│   ├── homepage_main/          # Home feed — posts, trending books, suggestions
│   ├── bookshelf/              # Bookshelf management + book detail views
│   ├── Club/                   # Club browsing, creation, detail, and chat
│   ├── Search/                 # User and book search
│   ├── Profile/                # User profile, settings, follow system
│   ├── FinalMessageNavigator/  # In-app messaging
│   ├── AppDelegate.swift       # App entry point
│   ├── AppDependencies.swift   # Centralized dependency container
│   └── SceneDelegate.swift     # Scene lifecycle management
│
└── .github/
    └── workflows/              # CI: Xcode Build & Analyze
```

---

## 📱 iOS App (Swift / UIKit)

The native iOS app is the core product. It is built with **UIKit**, architected around a **shared dependency container**, and connects to a **Firebase** backend.

### Modules

| Module | Path | Description |
|--------|------|-------------|
| **Home Feed** | `BookHive/homepage_main/` | Scrollable feed with club posts, trending books, and suggested users |
| **Bookshelf** | `BookHive/bookshelf/` | Personal library — add books, organize into custom lists, view details |
| **Clubs** | `BookHive/Club/` | Browse / create clubs, view club detail, join as member or admin, chat rooms, scheduled discussions |
| **Search** | `BookHive/Search/` | Search for books by title/author and discover other users |
| **Profile** | `BookHive/Profile/` | User profile page, follow/unfollow, settings panel |
| **Messaging** | `BookHive/FinalMessageNavigator/` | In-app direct messaging between users |

### Architecture

- **Dependency Injection** — `AppDependencies.swift` acts as a centralized singleton container holding all shared data models (`ClubsData`, `BookshelfData`, `FeedData`, `ProfileScreenModel`, `FollowRepository`, etc.)
- **UIKit + XIBs** — all screens are built programmatically or via `.xib` files; no SwiftUI
- **Firebase SDK** — `FirebaseManager.swift` handles auth (sign-in / sign-up) and exposes the shared Firebase instances.

### Tech Stack

| Layer | Technology |
|-------|-----------|
| Language | Swift 5 |
| UI Framework | UIKit |
| Backend | Firebase (Firestore, Cloud Storage) |
| Auth | Firebase Auth (`signIn`, `signUp`) |
| Data | Firebase SDK for iOS |
| CI | GitHub Actions — Xcode Build & Analyze |

### Running the App

> [!IMPORTANT]
> **ReadersHive can only be run on a Mac.** You need either an iOS Simulator (via Xcode) or a physically connected iPhone.

1. Open `BookHive/Club.xcodeproj` in **Xcode 15+**
2. Select an **iOS Simulator** or a **connected iPhone** (iOS 16+) from the device picker
3. Press **⌘ R** to build and run

> [!NOTE]
> The app is fully connected to the live Firebase backend.

---

## 🗄 Data Models

The Firestore schema is defined in `BookHive/Club/Model/Entities.swift`. Key collections and relationships:

| Table | Key Fields |
|-------|-----------|
| `clubs` | `id`, `name`, `category`, `description`, `image_path`, `member_count`, `visibility`, `created_by` |
| `club_members` | `club_id`, `user_id`, `role`, `joined_at` |
| `posts` | `id`, `user_id`, `club_id`, `title`, `content`, `upvotes`, `created_at` |
| `comments` | `comment_id`, `post_id`, `user_id`, `content`, `upvotes` |
| `discussions` | `id`, `club_id`, `title`, `date`, `meeting_link`, `created_by` |
| `chat_rooms` | `id`, `club_id`, `title`, `icon` |
| `tags` | `tag_id`, `name` |
| `post_tags` | `post_id`, `tag_id` |
| `post_likes` | `post_id`, `user_id` |

---

## 🚀 Backend Integration Status

The Firebase backend is fully connected and live.

| Feature | Status | Notes |
|---------|--------|-------|
| User Auth (sign up / sign in) | ✅ Completed | Fully functional authentication flow using Firebase Auth |
| Club data (live) | ✅ Completed | Live clubs query and creation via Firestore |
| Posts / Feed (live) | ✅ Completed | Dynamic feed from joined clubs |
| Bookshelf sync | ✅ Completed | Fully synced personal library |
| User profiles | ✅ Completed | Live user fetching and updates |
| Club membership writes | ✅ Completed | Joining/leaving clubs updates the backend |
| Messaging (real-time) | ✅ Completed | Real-time chat via Firestore `addSnapshotListener` |

---

## ✅ Current Status

- [x] Home feed UI — posts, trending books, suggested users
- [x] Bookshelf — add/remove books, custom lists, book detail view
- [x] Club browsing — list view, categories, sections (My Clubs / Recommended / Trending)
- [x] Club detail — posts, discussions, chat rooms, member list
- [x] Club creation flow
- [x] Search — book search + user discovery
- [x] Profile screen — user info, follow system, settings
- [x] In-app messaging navigator
- [x] `AppDependencies` container — shared data architecture
- [x] `FirebaseManager` — auth scaffolding (sign in / sign up)
- [x] GitHub Actions CI — Xcode build & analyze on push/PR
- [x] Live Firebase queries replacing mock data
- [x] Real-time chat via Firestore Realtime Sync
- [ ] Push notifications (to be implemented via Firebase)
- [x] Full authentication flow (login / register screens)

---

## 🤝 Contributing

This is a closed team project — **Team K**. To contribute:

1. Create a feature branch off `main`
2. Follow the existing module structure (one folder per feature)
3. Keep data models in sync with `Entities.swift`
4. Open a pull request — CI will run the Xcode build automatically

---

## 👥 Contributors

Built in 2026 as a collaborative iOS development project by **Team K**.

| Name | GitHub |
|------|--------|
| Aditya Sharma | [@Adi-1515](https://github.com/Adi-1515) |
| Manas Mehta | [@manas9568](https://github.com/manas9568) |
| Pawan Bisht | [@PawanBisht1](https://github.com/PawanBisht1) |
| Deepak Dumka | [@Deepakdumka1](https://github.com/Deepakdumka1) |

---

*ReadersHive — Where every book finds its flock. 🐝*
