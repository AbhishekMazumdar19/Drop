import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct UserModel: Codable, Identifiable {
    @DocumentID var id: String?

    var email: String
    var displayName: String
    var campusId: String
    var campusName: String
    var course: String?
    var profileImageURL: String?

    // Dynamic identity
    var currentVibe: String?
    var dropIdentity: String?

    // Stats
    var streakCount: Int
    var totalDrops: Int
    var onTimeDrops: Int
    var badges: [String]

    // App state
    var hasCompletedOnboarding: Bool
    var fcmToken: String?

    // Timestamps
    @ServerTimestamp var createdAt: Timestamp?
    @ServerTimestamp var lastActiveAt: Timestamp?

    // MARK: Computed
    var onTimeRate: Double {
        guard totalDrops > 0 else { return 0 }
        return Double(onTimeDrops) / Double(totalDrops)
    }

    var primaryBadgeId: String? { badges.first }

    var displayVibe: String {
        if let vibe = currentVibe, !vibe.isEmpty { return vibe }
        return dropIdentity ?? "campus native"
    }

    // MARK: - Static Factory
    static func new(id: String, email: String, displayName: String, campusId: String, campusName: String) -> UserModel {
        UserModel(
            id: id,
            email: email,
            displayName: displayName,
            campusId: campusId,
            campusName: campusName,
            course: nil,
            profileImageURL: nil,
            currentVibe: nil,
            dropIdentity: nil,
            streakCount: 0,
            totalDrops: 0,
            onTimeDrops: 0,
            badges: [],
            hasCompletedOnboarding: false,
            fcmToken: nil
        )
    }
}
