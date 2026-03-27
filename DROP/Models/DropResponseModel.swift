import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

// MARK: - Submission State
enum SubmissionState: String, Codable {
    case onTime = "onTime"
    case late   = "late"
}

// MARK: - Drop Response (Post)
struct DropResponseModel: Codable, Identifiable {
    @DocumentID var id: String?

    var dropId: String
    var userId: String
    var campusId: String

    // Media
    var imageURL: String

    // Optional metadata
    var caption: String?
    var vibeTag: String?
    var zoneId: String?
    var zoneName: String?

    // Timing
    var submissionState: SubmissionState
    @ServerTimestamp var createdAt: Timestamp?

    // Engagement
    var likeCount: Int
    var commentCount: Int
    var likedByUserIds: [String]    // Stored for fast like-state lookup (cap at 500 for MVP)

    // MARK: Computed
    var createdDate: Date { createdAt?.dateValue() ?? Date() }

    var isExpired: Bool {
        let expiry = Calendar.current.date(
            byAdding: .day,
            value: DropConfig.feedExpiryDays,
            to: createdDate
        ) ?? Date()
        return Date() > expiry
    }

    var isLate: Bool { submissionState == .late }

    func isLikedBy(userId: String) -> Bool {
        likedByUserIds.contains(userId)
    }

    // MARK: -  Factory
    static func new(
        dropId: String,
        userId: String,
        campusId: String,
        imageURL: String,
        caption: String?,
        vibeTag: String?,
        zoneId: String?,
        zoneName: String?,
        isLate: Bool
    ) -> DropResponseModel {
        DropResponseModel(
            id: nil,
            dropId: dropId,
            userId: userId,
            campusId: campusId,
            imageURL: imageURL,
            caption: caption,
            vibeTag: vibeTag,
            zoneId: zoneId,
            zoneName: zoneName,
            submissionState: isLate ? .late : .onTime,
            likeCount: 0,
            commentCount: 0,
            likedByUserIds: []
        )
    }
}

// MARK: - Drop Response + User (enriched for feed display)
struct FeedPost: Identifiable {
    let id: String
    let response: DropResponseModel
    let user: UserModel
    let dropTitle: String
    let dropPromptIcon: String

    var isLikedByCurrentUser: Bool = false
}
