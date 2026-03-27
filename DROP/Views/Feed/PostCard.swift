import SwiftUI

// MARK: - PostCard (feed item)
struct PostCard: View {

    let post: FeedPost
    let currentUserId: String
    var onLike: () -> Void
    var onTap: () -> Void

    @State private var isLikeAnimating = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Header
                postHeader
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)

                // Image
                postImage

                // Footer
                postFooter
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
            }
            .background(Color.dropCard)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Header
    private var postHeader: some View {
        HStack(spacing: 10) {
            AvatarView(
                imageURL: post.user.profileImageURL,
                displayName: post.user.displayName,
                size: 38,
                showStreakRing: post.user.streakCount >= 3,
                streakCount: post.user.streakCount
            )

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(post.user.displayName)
                        .font(DROPFont.body())
                        .foregroundColor(.white)

                    if let badgeId = post.user.primaryBadgeId {
                        BadgeChipView(badgeId: badgeId, compact: true)
                    }
                }

                HStack(spacing: 6) {
                    Text(post.dropPromptIcon)
                        .font(.system(size: 11))
                    Text(post.dropTitle)
                        .font(DROPFont.caption(11))
                        .foregroundColor(.dropTextSecondary)

                    if let zone = post.response.zoneName {
                        Text("·")
                            .foregroundColor(.dropTextTertiary)
                        Text(zone)
                            .font(DROPFont.caption(11))
                            .foregroundColor(.dropTextTertiary)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if post.response.isLate {
                    OnTimeBadge(isLate: true)
                }
                Text(post.response.createdDate.timeAgoDisplay())
                    .font(DROPFont.caption(11))
                    .foregroundColor(.dropTextTertiary)
            }
        }
    }

    // MARK: - Image
    private var postImage: some View {
        AsyncImage(url: URL(string: post.response.imageURL)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 320)
                    .clipped()
            case .failure:
                errorImagePlaceholder
            case .empty:
                Color.dropSurface
                    .frame(maxWidth: .infinity, maxHeight: 320)
                    .shimmer()
            @unknown default:
                Color.dropSurface.frame(maxWidth: .infinity, maxHeight: 320)
            }
        }
        .onTapGesture(count: 2) {
            doubleTapLike()
        }
    }

    private var errorImagePlaceholder: some View {
        Color.dropSurface
            .frame(maxWidth: .infinity, maxHeight: 200)
            .overlay(
                VStack(spacing: 4) {
                    Image(systemName: "photo.fill")
                        .foregroundColor(.dropTextTertiary)
                    Text("Can't load image")
                        .font(DROPFont.caption())
                        .foregroundColor(.dropTextTertiary)
                }
            )
    }

    // MARK: - Footer
    private var postFooter: some View {
        HStack(spacing: 16) {
            // Like button
            Button {
                doLike()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: post.isLikedByCurrentUser ? "heart.fill" : "heart")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(post.isLikedByCurrentUser ? .dropRed : .dropTextSecondary)
                        .scaleEffect(isLikeAnimating ? 1.3 : 1.0)

                    Text("\(post.response.likeCount)")
                        .font(DROPFont.body(14))
                        .foregroundColor(.dropTextSecondary)
                }
            }
            .buttonStyle(.plain)

            // Comment button
            HStack(spacing: 6) {
                Image(systemName: "bubble.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.dropTextSecondary)

                Text("\(post.response.commentCount)")
                    .font(DROPFont.body(14))
                    .foregroundColor(.dropTextSecondary)
            }

            Spacer()

            // Caption / vibe
            if let caption = post.response.caption {
                Text(caption.truncated(to: 60))
                    .font(DROPFont.body(13))
                    .foregroundColor(.dropTextSecondary)
                    .lineLimit(1)
            } else if let vibeTag = post.response.vibeTag,
                      let tag = VibeTag(rawValue: vibeTag) {
                HStack(spacing: 4) {
                    Text(tag.emoji)
                        .font(.system(size: 12))
                    Text(tag.rawValue)
                        .font(DROPFont.caption(11))
                        .foregroundColor(.dropTextTertiary)
                }
            }
        }
    }

    // MARK: - Like Actions
    private func doLike() {
        withAnimation(.dropSnap) { isLikeAnimating = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            isLikeAnimating = false
        }
        HapticFeedback.impact(.light)
        onLike()
    }

    private func doubleTapLike() {
        guard !post.isLikedByCurrentUser else { return }
        doLike()
    }
}
