import SwiftUI

@MainActor
final class CommentViewModel: ObservableObject {

    @Published var comments: [CommentModel] = []
    @Published var newCommentText: String = ""
    @Published var isLoading: Bool = false
    @Published var isPosting: Bool = false

    private let commentService = CommentService.shared
    private var listener: ListenerRegistration?

    // MARK: - Listen to Comments (Realtime)

    func listen(to responseId: String) {
        isLoading = true
        listener = commentService.listenToComments(responseId: responseId) { [weak self] comments in
            Task { @MainActor [weak self] in
                self?.comments = comments
                self?.isLoading = false
            }
        }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    // MARK: - Post Comment

    func postComment(responseId: String, user: UserModel) async {
        let text = newCommentText.trimmed
        guard !text.isEmpty, !isPosting else { return }

        newCommentText = ""
        isPosting = true
        defer { isPosting = false }

        let comment = CommentModel.new(
            responseId: responseId,
            userId: user.id ?? "",
            displayName: user.displayName,
            profileImageURL: user.profileImageURL,
            badgeId: user.primaryBadgeId,
            text: text
        )

        do {
            let saved = try await commentService.addComment(comment)
            // The listener will also pick this up; optimistic insert for speed
            if !comments.contains(where: { $0.id == saved.id }) {
                comments.append(saved)
            }
            HapticFeedback.impact(.light)
        } catch {
            newCommentText = text // restore on failure
        }
    }

    // MARK: - Delete Comment

    func deleteComment(_ comment: CommentModel) async {
        guard let id = comment.id else { return }
        comments.removeAll { $0.id == id }
        try? await commentService.deleteComment(commentId: id, responseId: comment.responseId)
    }

    deinit { listener?.remove() }
}
