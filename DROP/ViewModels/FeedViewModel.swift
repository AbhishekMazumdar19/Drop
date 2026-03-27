import SwiftUI

// MARK: - Feed Section
enum FeedSection: String, CaseIterable, Identifiable {
    case today   = "Today's Drop"
    case scenes  = "Scenes"
    case recent  = "This Week"

    var id: String { rawValue }
}

@MainActor
final class FeedViewModel: ObservableObject {

    // MARK: - Published State
    @Published var feedPosts: [FeedPost] = []
    @Published var todaysPosts: [FeedPost] = []
    @Published var selectedSection: FeedSection = .today
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isRefreshing: Bool = false

    // Vibe scene groupings (feed section 2)
    @Published var sceneGroups: [VibeTag: [FeedPost]] = [:]

    // MARK: - Services
    private let feedService = FeedService.shared
    private let dropService = DropService.shared

    // MARK: - Load Feed

    func loadFeed(campusId: String, currentUserId: String, activeDrop: DropModel?) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let allPostsTask  = feedService.fetchFeedPosts(campusId: campusId, currentUserId: currentUserId)
            async let todayTask     = loadTodayPosts(campusId: campusId, userId: currentUserId, drop: activeDrop)

            let allPosts = try await allPostsTask
            let today    = await todayTask

            self.feedPosts = allPosts
            self.todaysPosts = today
            self.sceneGroups = groupByVibe(posts: allPosts)
        } catch {
            errorMessage = "Couldn't load the feed. Pull down to try again."
        }
    }

    func refresh(campusId: String, currentUserId: String, activeDrop: DropModel?) async {
        isRefreshing = true
        defer { isRefreshing = false }
        await loadFeed(campusId: campusId, currentUserId: currentUserId, activeDrop: activeDrop)
    }

    // MARK: - Today's Posts Helper

    private func loadTodayPosts(campusId: String, userId: String, drop: DropModel?) async -> [FeedPost] {
        guard let dropId = drop?.id else { return [] }
        return (try? await feedService.fetchTodaysPosts(dropId: dropId, campusId: campusId, currentUserId: userId)) ?? []
    }

    // MARK: - Scene Grouping

    private func groupByVibe(posts: [FeedPost]) -> [VibeTag: [FeedPost]] {
        var grouped: [VibeTag: [FeedPost]] = [:]
        for post in posts {
            if let vibeRaw = post.response.vibeTag,
               let tag = VibeTag(rawValue: vibeRaw) {
                grouped[tag, default: []].append(post)
            }
        }
        return grouped
    }

    // MARK: - Like Toggle

    func toggleLike(post: FeedPost, currentUserId: String) async {
        guard let idx = feedPosts.firstIndex(where: { $0.id == post.id }) else { return }

        let wasLiked = feedPosts[idx].isLikedByCurrentUser
        let newLikeCount = wasLiked
            ? feedPosts[idx].response.likeCount - 1
            : feedPosts[idx].response.likeCount + 1

        // Optimistic update
        var updated = feedPosts[idx]
        var updatedResponse = updated.response
        updatedResponse.likeCount = newLikeCount
        updated = FeedPost(
            id: updated.id,
            response: updatedResponse,
            user: updated.user,
            dropTitle: updated.dropTitle,
            dropPromptIcon: updated.dropPromptIcon,
            isLikedByCurrentUser: !wasLiked
        )
        feedPosts[idx] = updated

        // Also update todaysPosts if present
        if let todayIdx = todaysPosts.firstIndex(where: { $0.id == post.id }) {
            todaysPosts[todayIdx] = updated
        }

        // Firestore update
        do {
            try await dropService.toggleLike(responseId: post.id, userId: currentUserId, isLiking: !wasLiked)
            HapticFeedback.impact(.light)
        } catch {
            // Revert on failure
            feedPosts[idx] = post
        }
    }

    // MARK: - Posts for selected section

    var postsForCurrentSection: [FeedPost] {
        switch selectedSection {
        case .today:  return todaysPosts
        case .scenes: return feedPosts
        case .recent: return feedPosts
        }
    }

    var activeScenes: [(tag: VibeTag, posts: [FeedPost])] {
        VibeTag.allCases
            .compactMap { tag -> (tag: VibeTag, posts: [FeedPost])? in
                guard let posts = sceneGroups[tag], !posts.isEmpty else { return nil }
                return (tag: tag, posts: posts)
            }
    }
}
