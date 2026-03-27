import Foundation
import FirebaseFirestore

struct ConversationModel: Codable, Identifiable {
    @DocumentID var id: String?

    var participantIds: [String]
    var lastMessage: String
    var lastMessageAt: Timestamp
    var lastSenderId: String

    // Unread tracking per participant: ["uid1": 2, "uid2": 0]
    var unreadCounts: [String: Int]

    var lastMessageDate: Date { lastMessageAt.dateValue() }

    func unreadCount(for userId: String) -> Int {
        unreadCounts[userId] ?? 0
    }

    func otherParticipantId(currentUserId: String) -> String? {
        participantIds.first { $0 != currentUserId }
    }

    static func new(between userA: String, and userB: String) -> ConversationModel {
        ConversationModel(
            participantIds: [userA, userB],
            lastMessage: "",
            lastMessageAt: Timestamp(date: Date()),
            lastSenderId: userA,
            unreadCounts: [userA: 0, userB: 0]
        )
    }
}
