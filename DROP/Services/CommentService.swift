import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

final class CommentService {

    static let shared = CommentService()
    private init() {}

    private let db = Firestore.firestore()
    private var commentsRef: CollectionReference { db.collection(Collections.comments) }

    // MARK: - Fetch Comments

    func fetchComments(for responseId: String) async throws -> [CommentModel] {
        let snapshot = try await commentsRef
            .whereField("responseId", isEqualTo: responseId)
            .order(by: "createdAt", descending: false)
            .getDocuments()
        return try snapshot.documents.compactMap { try $0.data(as: CommentModel.self) }
    }

    // MARK: - Listen to Comments (Realtime)

    func listenToComments(
        responseId: String,
        onUpdate: @escaping ([CommentModel]) -> Void
    ) -> ListenerRegistration {
        commentsRef
            .whereField("responseId", isEqualTo: responseId)
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { snapshot, _ in
                let comments = (snapshot?.documents ?? []).compactMap {
                    try? $0.data(as: CommentModel.self)
                }
                onUpdate(comments)
            }
    }

    // MARK: - Add Comment

    func addComment(_ comment: CommentModel) async throws -> CommentModel {
        let doc = commentsRef.document()
        var newComment = comment
        newComment.id = doc.documentID
        try doc.setData(from: newComment)

        // Increment the post's comment count
        try await DropService.shared.incrementCommentCount(responseId: comment.responseId)

        return newComment
    }

    // MARK: - Delete Comment

    func deleteComment(commentId: String, responseId: String) async throws {
        try await commentsRef.document(commentId).delete()
        try await DropService.shared.decrementCommentCount(responseId: responseId)
    }
}
