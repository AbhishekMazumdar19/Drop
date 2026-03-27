import SwiftUI

struct PostDetailView: View {

    let post: FeedPost
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var feedVM: FeedViewModel

    @StateObject private var commentVM = CommentViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var showMessageSheet = false
    @FocusState private var commentFieldFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dropBlack.ignoresSafeArea()

                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 0) {
                            // Post image + metadata
                            postImageSection

                            // Post info
                            postInfoSection
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)

                            Divider().background(Color.dropSurface)

                            // Comments
                            commentsSection
                                .id("comments")
                        }
                        .padding(.bottom, 80)
                    }
                    .onChange(of: commentVM.comments.count) { _, _ in
                        withAnimation { proxy.scrollTo("comments", anchor: .bottom) }
                    }
                }

                // Comment input
                VStack {
                    Spacer()
                    commentInputBar
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .font(.system(size: 14, weight: .bold))
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text(post.dropPromptIcon + " " + post.dropTitle)
                        .font(DROPFont.body())
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showMessageSheet = true
                    } label: {
                        Image(systemName: "paperplane")
                            .foregroundColor(.dropTextSecondary)
                    }
                }
            }
            .task {
                commentVM.listen(to: post.id)
            }
            .onDisappear {
                commentVM.stopListening()
            }
        }
    }

    // MARK: - Post Image
    private var postImageSection: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: URL(string: post.response.imageURL)) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().scaledToFit().frame(maxWidth: .infinity)
                default:
                    Color.dropSurface.frame(height: 340).shimmer(active: phase == .empty)
                }
            }

            // Late tag overlay
            if post.response.isLate {
                OnTimeBadge(isLate: true)
                    .padding(12)
            }
        }
    }

    // MARK: - Post Info
    private var postInfoSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // User row
            HStack(spacing: 12) {
                AvatarView(
                    imageURL: post.user.profileImageURL,
                    displayName: post.user.displayName,
                    size: 44,
                    showStreakRing: post.user.streakCount > 0,
                    streakCount: post.user.streakCount
                )

                VStack(alignment: .leading, spacing: 3) {
                    Text(post.user.displayName)
                        .font(DROPFont.headline())
                        .foregroundColor(.white)

                    HStack(spacing: 6) {
                        Text(post.user.displayVibe)
                            .font(DROPFont.body(12))
                            .foregroundColor(.dropOrange)

                        if post.user.streakCount > 0 {
                            StreakBadgeView(streak: post.user.streakCount, size: .small)
                        }
                    }
                }

                Spacer()

                Button {
                    Task {
                        await feedVM.toggleLike(
                            post: post,
                            currentUserId: appState.currentUser?.id ?? ""
                        )
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: post.isLikedByCurrentUser ? "heart.fill" : "heart")
                            .font(.system(size: 22))
                            .foregroundColor(post.isLikedByCurrentUser ? .dropRed : .dropTextSecondary)
                        Text("\(post.response.likeCount)")
                            .font(DROPFont.caption(11))
                            .foregroundColor(.dropTextSecondary)
                    }
                }
            }

            // Caption
            if let caption = post.response.caption {
                Text(caption)
                    .font(DROPFont.body())
                    .foregroundColor(.white)
            }

            // Zone + vibe tags
            HStack(spacing: 8) {
                if let zone = post.response.zoneName,
                   let zoneType = ZoneType(rawValue: zone) {
                    Label(zone, systemImage: "location.fill")
                        .font(DROPFont.caption(11))
                        .foregroundColor(.dropTextSecondary)
                }

                if let vibeRaw = post.response.vibeTag,
                   let tag = VibeTag(rawValue: vibeRaw) {
                    Text(tag.emoji + " " + tag.rawValue)
                        .font(DROPFont.caption(11))
                        .foregroundColor(.dropOrange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.dropOrange.opacity(0.1))
                        .cornerRadius(Radius.pill)
                }

                Spacer()

                Text(post.response.createdDate.timeAgoDisplay())
                    .font(DROPFont.caption(11))
                    .foregroundColor(.dropTextTertiary)
            }
        }
    }

    // MARK: - Comments
    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Comments")
                    .font(DROPFont.headline())
                    .foregroundColor(.white)
                Spacer()
                Text("\(commentVM.comments.count)")
                    .font(DROPFont.body(13))
                    .foregroundColor(.dropTextSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            if commentVM.isLoading {
                ProgressView().tint(.dropOrange).padding()
            } else if commentVM.comments.isEmpty {
                Text("No comments yet. Be the first.")
                    .font(DROPFont.body())
                    .foregroundColor(.dropTextTertiary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
            } else {
                ForEach(commentVM.comments) { comment in
                    CommentRow(
                        comment: comment,
                        currentUserId: appState.currentUser?.id ?? "",
                        onDelete: {
                            Task { await commentVM.deleteComment(comment) }
                        }
                    )
                }
            }
        }
    }

    // MARK: - Comment Input
    private var commentInputBar: some View {
        HStack(spacing: 12) {
            AvatarView(
                imageURL: appState.currentUser?.profileImageURL,
                displayName: appState.currentUser?.displayName ?? "?",
                size: 32
            )

            TextField("Add a comment...", text: $commentVM.newCommentText)
                .font(DROPFont.body())
                .foregroundColor(.white)
                .focused($commentFieldFocused)
                .submitLabel(.send)
                .onSubmit {
                    sendComment()
                }

            if !commentVM.newCommentText.isEmpty {
                Button {
                    sendComment()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(LinearGradient.dropFireGradient)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle().fill(Color.dropSurface.opacity(0.5)).frame(height: 0.5),
            alignment: .top
        )
    }

    private func sendComment() {
        guard let user = appState.currentUser else { return }
        Task {
            await commentVM.postComment(responseId: post.id, user: user)
        }
    }
}

// MARK: - CommentRow
struct CommentRow: View {
    let comment: CommentModel
    let currentUserId: String
    var onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            AvatarView(
                imageURL: comment.userProfileImageURL,
                displayName: comment.userDisplayName,
                size: 32
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(comment.userDisplayName)
                        .font(DROPFont.body(13))
                        .foregroundColor(.white)

                    if let badgeId = comment.userBadge {
                        BadgeChipView(badgeId: badgeId, compact: true)
                    }

                    Spacer()

                    Text(comment.createdDate.timeAgoDisplay())
                        .font(DROPFont.caption(10))
                        .foregroundColor(.dropTextTertiary)
                }

                Text(comment.text)
                    .font(DROPFont.body(14))
                    .foregroundColor(.dropTextSecondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .contextMenu {
            if comment.userId == currentUserId {
                Button(role: .destructive) { onDelete() } label: {
                    Label("Delete comment", systemImage: "trash")
                }
            }
        }
    }
}
