import Foundation
import FirebaseFirestore

struct MessageModel: Codable, Identifiable {
    @DocumentID var id: String?

    var conversationId: String
    var senderId: String
    var text: String
    var isRead: Bool

    @ServerTimestamp var createdAt: Timestamp?

    var createdDate: Date { createdAt?.dateValue() ?? Date() }

    static func new(conversationId: String, senderId: String, text: String) -> MessageModel {
        MessageModel(
            conversationId: conversationId,
            senderId: senderId,
            text: text,
            isRead: false
        )
    }
}
