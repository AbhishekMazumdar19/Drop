import Foundation
import FirebaseFirestore

// MARK: - MockData — used for Debug/Demo mode and local testing
struct MockData {

    // MARK: - Campus
    static let demoCampus = CampusModel(
        id: "campus_demo",
        name: "Demo Campus",
        city: "Anywhere",
        country: "US",
        shortCode: "DEMO",
        timezone: "America/New_York"
    )

    // MARK: - Users
    static func mockUsers(campusId: String = "campus_demo") -> [UserModel] {
        [
            UserModel(
                id: "user_alex",
                email: "alex@demo.edu",
                displayName: "Alex Chen",
                campusId: campusId,
                campusName: "Demo Campus",
                course: "Computer Science",
                profileImageURL: nil,
                currentVibe: VibeOption.deadlineMode.rawValue,
                dropIdentity: "Consistent Grinder",
                streakCount: 12,
                totalDrops: 22,
                onTimeDrops: 20,
                badges: [BadgeID.weekWarrior.rawValue, BadgeID.alwaysOnTime.rawValue, BadgeID.firstDrop.rawValue],
                hasCompletedOnboarding: true
            ),
            UserModel(
                id: "user_maya",
                email: "maya@demo.edu",
                displayName: "Maya Osei",
                campusId: campusId,
                campusName: "Demo Campus",
                course: "Psychology",
                profileImageURL: nil,
                currentVibe: VibeOption.mainCharacter.rawValue,
                dropIdentity: "Chaos Agent",
                streakCount: 3,
                totalDrops: 8,
                onTimeDrops: 4,
                badges: [BadgeID.chaosAgent.rawValue, BadgeID.firstDrop.rawValue],
                hasCompletedOnboarding: true
            ),
            UserModel(
                id: "user_jordan",
                email: "jordan@demo.edu",
                displayName: "Jordan Lee",
                campusId: campusId,
                campusName: "Demo Campus",
                course: nil,
                profileImageURL: nil,
                currentVibe: VibeOption.gymArc.rawValue,
                dropIdentity: "Night Owl",
                streakCount: 7,
                totalDrops: 15,
                onTimeDrops: 9,
                badges: [BadgeID.nightOwl.rawValue, BadgeID.weekWarrior.rawValue],
                hasCompletedOnboarding: true
            ),
            UserModel(
                id: "user_priya",
                email: "priya@demo.edu",
                displayName: "Priya Shah",
                campusId: campusId,
                campusName: "Demo Campus",
                course: "Economics",
                profileImageURL: nil,
                currentVibe: VibeOption.libraryPrison.rawValue,
                dropIdentity: "Late Merchant",
                streakCount: 0,
                totalDrops: 5,
                onTimeDrops: 1,
                badges: [BadgeID.lateMerchant.rawValue, BadgeID.firstDrop.rawValue],
                hasCompletedOnboarding: true
            ),
        ]
    }

    // MARK: - Active Drop
    static func mockActiveDrop(campusId: String = "campus_demo") -> DropModel {
        let now = Date()
        let prompt = DropPrompts.all[1]
        return DropModel(
            id: "drop_demo_001",
            title: prompt.title,
            prompt: prompt.prompt,
            promptIcon: prompt.icon,
            campusId: campusId,
            startsAt: Timestamp(date: now.addingTimeInterval(-60)),
            endsAt: Timestamp(date: now.addingTimeInterval(DropConfig.windowDurationSeconds)),
            graceEndsAt: Timestamp(date: now.addingTimeInterval(DropConfig.windowDurationSeconds + DropConfig.gracePeriodSeconds)),
            status: .active,
            allowedMediaType: "image"
        )
    }

    // MARK: - Mock Feed Posts
    static func mockFeedPosts(campusId: String = "campus_demo") -> [FeedPost] {
        let users = mockUsers(campusId: campusId)
        let drop = mockActiveDrop(campusId: campusId)

        let zones = [
            (id: "campus_demo_library", name: "Library"),
            (id: "campus_demo_cafe", name: "Cafe"),
            (id: "campus_demo_gym", name: "Gym"),
        ]

        let captions = [
            "literally cannot function without this ☕",
            "chaos mode: activated",
            "the grind never stops fr",
            "vibing at capacity",
            "this is fine 🔥",
        ]

        var posts: [FeedPost] = []
        for (i, user) in users.enumerated() {
            let zone = zones[i % zones.count]
            let isLate = i % 3 == 2

            let response = DropResponseModel(
                id: "response_demo_\(i)",
                dropId: drop.id ?? "drop_demo_001",
                userId: user.id ?? "user_\(i)",
                campusId: campusId,
                imageURL: "https://picsum.photos/seed/drop\(i)/600/800",
                caption: captions[i % captions.count],
                vibeTag: VibeTag.allCases[i % VibeTag.allCases.count].rawValue,
                zoneId: zone.id,
                zoneName: zone.name,
                submissionState: isLate ? .late : .onTime,
                createdAt: Timestamp(date: Date().addingTimeInterval(TimeInterval(-i * 300))),
                likeCount: Int.random(in: 0...42),
                commentCount: Int.random(in: 0...8),
                likedByUserIds: []
            )

            posts.append(FeedPost(
                id: "response_demo_\(i)",
                response: response,
                user: user,
                dropTitle: drop.title,
                dropPromptIcon: drop.promptIcon,
                isLikedByCurrentUser: i % 4 == 0
            ))
        }
        return posts
    }

    // MARK: - Mock Conversations
    static func mockConversations(currentUserId: String) -> [ConversationModel] {
        let users = mockUsers()
        return users.prefix(2).map { user in
            ConversationModel(
                id: "conv_\(currentUserId)_\(user.id ?? "x")",
                participantIds: [currentUserId, user.id ?? "x"],
                lastMessage: "yo what are you dropping today",
                lastMessageAt: Timestamp(date: Date().addingTimeInterval(-600)),
                lastSenderId: user.id ?? "x",
                unreadCounts: [currentUserId: 1, user.id ?? "x": 0]
            )
        }
    }

    // MARK: - Mock Comments
    static func mockComments(for responseId: String) -> [CommentModel] {
        let users = mockUsers()
        return [
            CommentModel(id: "c1", responseId: responseId, userId: users[0].id ?? "", userDisplayName: users[0].displayName, userProfileImageURL: nil, userBadge: users[0].primaryBadgeId, text: "ngl this is the best drop today 🔥"),
            CommentModel(id: "c2", responseId: responseId, userId: users[1].id ?? "", userDisplayName: users[1].displayName, userProfileImageURL: nil, userBadge: nil, text: "lowkey same energy rn"),
            CommentModel(id: "c3", responseId: responseId, userId: users[2].id ?? "", userDisplayName: users[2].displayName, userProfileImageURL: nil, userBadge: users[2].primaryBadgeId, text: "where is this???"),
        ]
    }
}
