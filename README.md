# DROP — Campus Social Network (iOS MVP)

A native iOS social networking app for campus communities. Built with SwiftUI + Firebase.

---

## What Is DROP?

DROP is a participation-gated, prompt-driven social app for university campuses.

- Users must complete a **Drop** (a timed photo challenge) to unlock the social feed
- Content is **ephemeral** — only visible for 7 days
- **No followers.** Social status is built via streaks, badges, and participation
- The feed is a live campus layer, not a generic social scroll

---

## Tech Stack

- **Swift + SwiftUI** (iOS 16+)
- **Firebase Auth** — Email/password auth
- **Cloud Firestore** — Real-time database
- **Firebase Storage** — Image uploads
- **Firebase Cloud Messaging** — Push notifications
- **MVVM architecture** — Clean service/repository/viewmodel separation

---

## Project Structure

```
DROP/
├── App/
│   ├── DROPApp.swift           # App entry, Firebase config
│   ├── AppDelegate.swift       # FCM + notification delegate
│   ├── AppState.swift          # Global auth + nav state machine
│   └── RootView.swift          # Root routing (splash → auth → onboarding → main)
├── Core/
│   ├── Constants.swift         # Firestore collection names, app-wide constants
│   └── Theme.swift             # Design system: colors, typography, spacing
├── Models/
│   ├── UserModel.swift         # User profile
│   ├── DropModel.swift         # Drop event (prompt + time window)
│   ├── DropResponseModel.swift # User's Drop submission (post)
│   ├── CommentModel.swift      # Post comment
│   ├── ConversationModel.swift # DM conversation
│   ├── MessageModel.swift      # DM message
│   ├── CampusModel.swift       # University/campus
│   ├── ZoneModel.swift         # Campus zone (Library, Gym, etc.)
│   └── BadgeModel.swift        # Badge definitions + rules
├── Services/
│   ├── AuthService.swift       # Firebase Auth wrapper
│   ├── UserService.swift       # User CRUD
│   ├── DropService.swift       # Drop + response management
│   ├── FeedService.swift       # Feed queries (7-day window)
│   ├── MediaUploadService.swift # Image compress + Storage upload
│   ├── MessageService.swift    # DM conversations
│   ├── NotificationService.swift # FCM + local notifications
│   └── CampusService.swift     # Campus + zone data
├── ViewModels/
│   ├── AuthViewModel.swift
│   ├── OnboardingViewModel.swift
│   ├── FeedViewModel.swift
│   ├── DropViewModel.swift
│   ├── ProfileViewModel.swift
│   ├── CampusViewModel.swift
│   └── MessagesViewModel.swift
├── Views/
│   ├── Auth/                   # Splash, Login, SignUp
│   ├── Onboarding/             # Welcome → Campus → Name → DP → Vibe → First Drop
│   ├── Feed/                   # FeedView, LockedFeedView, PostCard, PostDetail
│   ├── Drop/                   # DropView, DropCapture, DropSuccess, ActiveDropBanner
│   ├── Campus/                 # CampusView (zones), ZoneDetail
│   ├── Messages/               # MessagesList, Chat
│   ├── Profile/                # ProfileView, EditProfile, BadgesView
│   ├── Debug/                  # DebugAdminView (manual drop trigger, seed data)
│   └── Main/                   # MainTabView
├── Components/
│   ├── AvatarView.swift        # User avatar with streak ring
│   ├── BadgeChipView.swift     # Badge pill chip
│   ├── StreakBadgeView.swift   # Streak counter display
│   ├── CountdownView.swift     # Drop countdown timer
│   ├── PostCard.swift          # Feed post card component
│   └── ImagePicker.swift       # PHPickerViewController + Camera wrapper
└── Utilities/
    ├── Extensions.swift        # View, Color, Date extensions
    ├── DateUtils.swift         # Drop timing, expiry, streak logic
    └── MockData.swift          # Demo/seed data for testing
```

---

## Setup Guide

### Prerequisites

- **macOS Ventura+** with **Xcode 15+**
- A **Firebase project** (free Spark tier works)
- An iOS device or Simulator (iOS 16+)

---

### Step 1: Create the Xcode Project

1. Open Xcode → **File → New → Project**
2. Choose **iOS → App**
3. Settings:
   - Product Name: `DROP`
   - Bundle Identifier: `com.yourcompany.drop`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - ✅ Include Tests (optional)
4. Save to your preferred location
5. Delete the auto-generated `ContentView.swift`

---

### Step 2: Add Firebase via Swift Package Manager

1. In Xcode: **File → Add Package Dependencies**
2. Enter URL: `https://github.com/firebase/firebase-ios-sdk`
3. Dependency Rule: **Up to Next Major Version** (10.0.0 <)
4. Click **Add Package**
5. Select these libraries:
   - ✅ `FirebaseAuth`
   - ✅ `FirebaseFirestore`
   - ✅ `FirebaseFirestoreSwift`
   - ✅ `FirebaseStorage`
   - ✅ `FirebaseMessaging`

---

### Step 3: Firebase Console Setup

1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Create project → name it **DROP**
3. Add an **iOS app**:
   - Bundle ID: same as your Xcode bundle ID
   - Download `GoogleService-Info.plist`
   - Drag into your Xcode project root → check **"Add to target: DROP"**
4. Enable services:
   - **Authentication** → Sign-in method → Email/Password → Enable
   - **Firestore Database** → Create database (Start in test mode for MVP)
   - **Storage** → Get started
   - **Cloud Messaging** → Configure for push (optional for MVP demo)

---

### Step 4: Copy Source Files

Copy all files from this repo's `DROP/` folder into your Xcode project, maintaining the folder structure.

In Xcode, you can:
- Drag and drop the entire folder structure into the Project Navigator
- Or create the groups manually and add the `.swift` files

---

### Step 5: Configure Xcode Capabilities

1. Select your project target → **Signing & Capabilities**
2. Click **+ Capability** and add:
   - **Push Notifications**
   - **Background Modes** → check "Remote notifications"

---

### Step 6: Replace Placeholder Config

In `Constants.swift`, replace:
```swift
static let campusSeedData = ...
```
with your actual campus data if needed.

The `GoogleService-Info.plist` you downloaded from Firebase handles all connection config automatically.

---

### Step 7: Firestore Security Rules (MVP)

In Firebase Console → Firestore → Rules, replace with:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    match /drops/{dropId} {
      allow read: if request.auth != null;
      allow write: if false; // system-only writes; use Debug view for MVP
    }
    match /dropResponses/{responseId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && request.auth.uid == request.resource.data.userId;
      allow update: if request.auth != null; // for likes/comments
    }
    match /comments/{commentId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && request.auth.uid == request.resource.data.userId;
      allow delete: if request.auth != null && request.auth.uid == resource.data.userId;
    }
    match /conversations/{convId} {
      allow read, write: if request.auth != null && 
        request.auth.uid in resource.data.participantIds;
    }
    match /messages/{msgId} {
      allow read, write: if request.auth != null;
    }
    match /campuses/{campusId} {
      allow read: if request.auth != null;
    }
    match /zones/{zoneId} {
      allow read: if request.auth != null;
    }
  }
}
```

---

### Step 8: Storage Rules (MVP)

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.resource.size < 10 * 1024 * 1024;
    }
  }
}
```

---

## Running the MVP

Build and run on:
- **iOS Simulator (iPhone 15 Pro)** — recommended for demo
- Physical iPhone (requires paid Apple Developer account for real push notifications)

The app boots to Splash → Auth → Onboarding → First Drop → Feed.

---

## Demo / Debug Mode

There's a **Debug tab** (last tab in main nav) with tools to:

- **Trigger a Drop** — create an active Drop with a random prompt so users can respond
- **Seed demo users** — populate the feed with mock posts
- **Simulate streak change** — test streak logic
- **Mark Drop active/expired** — test locked/unlocked feed states
- **Switch campus** — change campus context

Use the Debug tab to demo the full loop without waiting for scheduled drops.

---

## Key Product Flows

```
FLOW 1: New User
Splash → SignUp → Choose Campus → Enter Name → Upload DP → 
Choose Vibe → Complete First Drop → Feed Unlocked ✓

FLOW 2: Returning user, no Drop yet today
Launch → Main app → Feed is LOCKED → CTA to Drop → 
Drop Capture → Submit → Feed Unlocked ✓

FLOW 3: Returning user, already dropped
Launch → Main app → Feed Unlocked → Scroll → Like/Comment

FLOW 4: Late drop
User opens app after Drop window closes → "Late Drop" option → 
Submit → Feed unlocks but streak does NOT increase
```

---

## Data Model Overview

| Collection | Key Fields |
|---|---|
| `users` | email, displayName, campusId, streakCount, totalDrops, badges[], currentVibe, dropIdentity |
| `drops` | title, prompt, campusId, startsAt, endsAt, graceEndsAt, status |
| `dropResponses` | dropId, userId, imageURL, caption, vibeTag, zoneId, submissionState, likeCount |
| `comments` | responseId, userId, text |
| `conversations` | participantIds[], lastMessage, lastMessageAt |
| `messages` | conversationId, senderId, text, isRead |
| `campuses` | name, city |
| `zones` | campusId, name, type |

---

## Known MVP Limitations (TODOs for v2)

- [ ] Campus email validation (currently any email works)
- [ ] Backend Drop scheduling (currently manual trigger via Debug view)
- [ ] Video Drop responses (architecture supports it, UI is image-only)
- [ ] Moderation/reporting
- [ ] Deep link from push notification to Drop capture
- [ ] Infinite scroll pagination
- [ ] Exact GPS (currently zone-based only)
- [ ] Group chats
- [ ] Block/report users
