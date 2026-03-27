import SwiftUI

// MARK: - Messages List View
struct MessagesView: View {

    @EnvironmentObject private var appState: AppState
    @StateObject private var messagesVM = MessagesViewModel()
    @State private var newChatUserId: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dropBlack.ignoresSafeArea()

                if messagesVM.isLoading {
                    loadingView
                } else if messagesVM.conversations.isEmpty {
                    emptyState
                } else {
                    conversationList
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Messages")
                        .font(DROPFont.headline())
                        .foregroundColor(.white)
                }
            }
        }
        .task {
            await messagesVM.loadConversations(currentUserId: appState.currentUser?.id ?? "")
        }
    }

    // MARK: - Conversation List
    private var conversationList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(messagesVM.conversations, id: \.id) { conv in
                    let otherId = conv.otherParticipantId(currentUserId: appState.currentUser?.id ?? "") ?? ""
                    let otherUser = messagesVM.conversationUsers[otherId]
                    NavigationLink {
                        ChatView(
                            conversation: conv,
                            otherUser: otherUser
                        )
                        .environmentObject(appState)
                        .environmentObject(messagesVM)
                    } label: {
                        ConversationRow(conversation: conv, otherUser: otherUser, currentUserId: appState.currentUser?.id ?? "")
                    }
                    .buttonStyle(.plain)

                    Divider()
                        .background(Color.dropDivider)
                        .padding(.leading, 76)
                }
            }
        }
    }

    // MARK: - Empty
    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("💬")
                .font(.system(size: 56))
            Text("No messages yet")
                .font(DROPFont.headline())
                .foregroundColor(.white)
            Text("React to someone's Drop to start a conversation.")
                .font(DROPFont.body())
                .foregroundColor(.dropTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    // MARK: - Loading
    private var loadingView: some View {
        ProgressView()
            .tint(.dropOrange)
    }
}

// MARK: - Conversation Row
private struct ConversationRow: View {

    let conversation: ConversationModel
    let otherUser: UserModel?
    let currentUserId: String

    private var unread: Int {
        conversation.unreadCounts[currentUserId] ?? 0
    }

    var body: some View {
        HStack(spacing: 14) {
            AvatarView(user: otherUser, size: 50, showStreakRing: false)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(otherUser?.displayName ?? "Unknown")
                        .font(DROPFont.headline(15))
                        .foregroundColor(.white)
                    Spacer()
                    Text(conversation.lastMessageAt.dateValue().timeAgoDisplay())
                        .font(DROPFont.body(12))
                        .foregroundColor(.dropTextSecondary)
                }

                HStack {
                    Text(conversation.lastMessage)
                        .font(DROPFont.body(14))
                        .foregroundColor(unread > 0 ? .white : .dropTextSecondary)
                        .lineLimit(1)
                    Spacer()
                    if unread > 0 {
                        Text("\(unread)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.dropOrange)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(unread > 0 ? Color.dropOrange.opacity(0.04) : Color.clear)
    }
}

// MARK: - Chat View
struct ChatView: View {

    let conversation: ConversationModel
    let otherUser: UserModel?

    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var messagesVM: MessagesViewModel

    @State private var messageText: String = ""
    @State private var scrollProxy: ScrollViewProxy?
    @FocusState private var isInputFocused: Bool

    var body: some View {
        ZStack {
            Color.dropBlack.ignoresSafeArea()

            VStack(spacing: 0) {
                messageList
                Divider().background(Color.dropDivider)
                inputBar
            }
        }
        .navigationTitle(otherUser?.displayName ?? "Chat")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                if let user = otherUser {
                    HStack(spacing: 8) {
                        AvatarView(user: user, size: 32, showStreakRing: false)
                        Text(user.displayName)
                            .font(DROPFont.headline(16))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .task {
            await messagesVM.openChat(
                conversationId: conversation.id ?? "",
                currentUserId: appState.currentUser?.id ?? ""
            )
        }
        .onDisappear { messagesVM.stopListeningToChat() }
    }

    // MARK: - Message List
    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(messagesVM.messages, id: \.id) { message in
                        MessageBubble(
                            message: message,
                            isOwn: message.senderId == appState.currentUser?.id
                        )
                        .id(message.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .onAppear { scrollProxy = proxy }
            .onChange(of: messagesVM.messages.count) { _, _ in
                if let last = messagesVM.messages.last?.id {
                    withAnimation { proxy.scrollTo(last, anchor: .bottom) }
                }
            }
        }
    }

    // MARK: - Input Bar
    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Message…", text: $messageText, axis: .vertical)
                .font(DROPFont.body(15))
                .foregroundColor(.white)
                .tint(.dropOrange)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.dropCard)
                .cornerRadius(Radius.pill)
                .lineLimit(4)
                .focused($isInputFocused)

            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(
                        messageText.trimmed.isEmpty
                            ? AnyShapeStyle(Color.dropTextSecondary)
                            : AnyShapeStyle(LinearGradient.dropFireGradient)
                    )
            }
            .disabled(messageText.trimmed.isEmpty || messagesVM.isSending)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.dropBlack)
    }

    private func sendMessage() {
        let text = messageText.trimmed
        guard !text.isEmpty else { return }
        messageText = ""
        HapticFeedback.impact(.light)

        Task {
            messagesVM.newMessageText = text
            await messagesVM.sendMessage(
                conversationId: conversation.id ?? "",
                senderId: appState.currentUser?.id ?? ""
            )
        }
    }
}

// MARK: - Message Bubble
private struct MessageBubble: View {

    let message: MessageModel
    let isOwn: Bool

    var body: some View {
        HStack {
            if isOwn { Spacer(minLength: 60) }

            Text(message.text)
                .font(DROPFont.body(15))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isOwn ? Color.dropOrange : Color.dropCard)
                .cornerRadius(isOwn ? 18 : 18, corners: isOwn ? [.topLeft, .topRight, .bottomLeft] : [.topLeft, .topRight, .bottomRight])

            if !isOwn { Spacer(minLength: 60) }
        }
    }
}

// MARK: - Rounded Corner extension helper
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

private struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
