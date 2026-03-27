import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

final class MessageService {

    static let shared = MessageService()
    private init() {}

    private let db = Firestore.firestore()
    private var convsRef: CollectionReference { db.collection(Collections.conversations) }
    private var msgsRef: CollectionReference  { db.collection(Collections.messages) }

    // MARK: - Get or Create Conversation

    func getOrCreateConversation(between userA: String, and userB: String) async throws -> ConversationModel {
        // Check if conversation already exists
        let snapshot = try await convsRef
            .whereField("participantIds", arrayContains: userA)
            .getDocuments()

        let existing = try snapshot.documents
            .compactMap { try? $0.data(as: ConversationModel.self) }
            .first { $0.participantIds.contains(userB) }

        if let conv = existing { return conv }

        // Create new conversation
        let conv = ConversationModel.new(between: userA, and: userB)
        let doc = convsRef.document()
        try doc.setData(from: conv)

        var created = conv
        created.id = doc.documentID
        return created
    }

    // MARK: - Fetch Conversations for User

    func fetchConversations(userId: String) async throws -> [ConversationModel] {
        let snapshot = try await convsRef
            .whereField("participantIds", arrayContains: userId)
            .order(by: "lastMessageAt", descending: true)
            .getDocuments()

        return try snapshot.documents.compactMap { try $0.data(as: ConversationModel.self) }
    }

    // MARK: - Listen to Messages in Conversation (Realtime)

    func listenToMessages(
        conversationId: String,
        onUpdate: @escaping ([MessageModel]) -> Void
    ) -> ListenerRegistration {
        msgsRef
            .whereField("conversationId", isEqualTo: conversationId)
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { snapshot, _ in
                let msgs = (snapshot?.documents ?? []).compactMap {
                    try? $0.data(as: MessageModel.self)
                }
                onUpdate(msgs)
            }
    }

    // MARK: - Send Message

    func sendMessage(_ message: MessageModel) async throws {
        guard let convId = message.conversationId as String? else { return }

        // Write message
        let msgDoc = msgsRef.document()
        var msg = message
        msg.id = msgDoc.documentID
        try msgDoc.setData(from: msg)

        // Update conversation metadata
        let batch = db.batch()
        let convRef = convsRef.document(convId)
        batch.updateData([
            "lastMessage": message.text,
            "lastMessageAt": FieldValue.serverTimestamp(),
            "lastSenderId": message.senderId
        ], forDocument: convRef)
        try await batch.commit()
    }

    // MARK: - Mark Messages as Read

    func markAsRead(conversationId: String, userId: String) async throws {
        try await convsRef.document(conversationId).updateData([
            "unreadCounts.\(userId)": 0
        ])
    }
}
