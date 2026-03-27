import SwiftUI

@MainActor
final class MessagesViewModel: ObservableObject {

    @Published var conversations: [ConversationModel] = []
    @Published var conversationUsers: [String: UserModel] = [:]
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // Active chat
    @Published var messages: [MessageModel] = []
    @Published var newMessageText: String = ""
    @Published var isSending: Bool = false

    private let messageService = MessageService.shared
    private let userService    = UserService.shared
    private var chatListener: ListenerRegistration?

    // MARK: - Load Conversations

    func loadConversations(userId: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let convs = try await messageService.fetchConversations(userId: userId)
            self.conversations = convs

            // Enrich with other participant's user data
            let otherIds = convs.compactMap { $0.otherParticipantId(currentUserId: userId) }
            for otherId in otherIds {
                if let user = try? await userService.fetchUser(id: otherId) {
                    conversationUsers[otherId] = user
                }
            }
        } catch {
            errorMessage = "Failed to load messages."
        }
    }

    // MARK: - Open Chat

    func openChat(conversationId: String, currentUserId: String) {
        stopListeningToChat()
        chatListener = messageService.listenToMessages(conversationId: conversationId) { [weak self] msgs in
            Task { @MainActor [weak self] in
                self?.messages = msgs
            }
        }
        Task {
            try? await messageService.markAsRead(conversationId: conversationId, userId: currentUserId)
        }
    }

    func stopListeningToChat() {
        chatListener?.remove()
        chatListener = nil
        messages = []
    }

    // MARK: - Send Message

    func sendMessage(conversationId: String, senderId: String) async {
        let text = newMessageText.trimmed
        guard !text.isEmpty else { return }

        newMessageText = ""
        isSending = true
        defer { isSending = false }

        let msg = MessageModel.new(conversationId: conversationId, senderId: senderId, text: text)
        do {
            try await messageService.sendMessage(msg)
        } catch {
            errorMessage = "Failed to send message."
            newMessageText = text // restore
        }
    }

    // MARK: - Get or Create Conversation

    func startConversation(between currentUserId: String, and otherUserId: String) async -> ConversationModel? {
        return try? await messageService.getOrCreateConversation(between: currentUserId, and: otherUserId)
    }

    // MARK: - Total Unread Count

    func totalUnread(userId: String) -> Int {
        conversations.reduce(0) { $0 + $1.unreadCount(for: userId) }
    }

    deinit {
        chatListener?.remove()
    }
}
