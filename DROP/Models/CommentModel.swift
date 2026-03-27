import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct CommentModel: Codable, Identifiable {
    @DocumentID var id: String?

    var responseId: String
    var userId: String
    var userDisplayName: String
    var userProfileImageURL: String?
    var userBadge: String?          // Primary badge id, denormalized for display speed

    var text: String

    @ServerTimestamp var createdAt: Timestamp?

    var createdDate: Date { createdAt?.dateValue() ?? Date() }

    static func new(
        responseId: String,
        userId: String,
        displayName: String,
        profileImageURL: String?,
        badgeId: String?,
        text: String
    ) -> CommentModel {
        CommentModel(
            responseId: responseId,
            userId: userId,
            userDisplayName: displayName,
            userProfileImageURL: profileImageURL,
            userBadge: badgeId,
            text: text
        )
    }
}
