import Foundation
import FirebaseFirestore

final class FeedService {

    static let shared = FeedService()
    private init() {}

    private let db = Firestore.firestore()
    private let userService = UserService.shared
    private let dropService = DropService.shared

    // MARK: - Build Enriched Feed Posts

    /// Fetches drop responses + enriches with user data and drop metadata
    func fetchFeedPosts(campusId: String, currentUserId: String) async throws -> [FeedPost] {
        let responses = try await dropService.fetchFeedResponses(campusId: campusId)

        // Collect unique user IDs and drop IDs
        let userIds = Array(Set(responses.map { $0.userId }))
        let dropIds = Array(Set(responses.map { $0.dropId }))

        // Batch fetch users and drops in parallel
        async let userMap = fetchUsersMap(ids: userIds)
        async let dropMap = fetchDropsMap(ids: dropIds)

        let users = try await userMap
        let drops = try await dropMap

        // Build enriched FeedPost objects
        var feedPosts: [FeedPost] = []
        for response in responses {
            guard
                let responseId = response.id,
                let user = users[response.userId]
            else { continue }

            let drop = drops[response.dropId]
            let post = FeedPost(
                id: responseId,
                response: response,
                user: user,
                dropTitle: drop?.title ?? "Drop",
                dropPromptIcon: drop?.promptIcon ?? "📸",
                isLikedByCurrentUser: response.isLikedBy(userId: currentUserId)
            )
            feedPosts.append(post)
        }

        return feedPosts
    }

    // MARK: - Fetch Today's (current active drop's) Posts

    func fetchTodaysPosts(dropId: String, campusId: String, currentUserId: String) async throws -> [FeedPost] {
        let responses = try await dropService.fetchResponsesForDrop(dropId: dropId)

        let userIds = Array(Set(responses.map { $0.userId }))
        let users = try await fetchUsersMap(ids: userIds)

        var posts: [FeedPost] = []
        for response in responses {
            guard let responseId = response.id,
                  let user = users[response.userId] else { continue }
            posts.append(FeedPost(
                id: responseId,
                response: response,
                user: user,
                dropTitle: "Today's Drop",
                dropPromptIcon: "📸",
                isLikedByCurrentUser: response.isLikedBy(userId: currentUserId)
            ))
        }
        return posts
    }

    // MARK: - Zone Posts

    func fetchZonePosts(campusId: String, zoneId: String, currentUserId: String) async throws -> [FeedPost] {
        let responses = try await dropService.fetchResponsesForZone(campusId: campusId, zoneId: zoneId)
        let userIds = Array(Set(responses.map { $0.userId }))
        let users = try await fetchUsersMap(ids: userIds)

        return responses.compactMap { response in
            guard let responseId = response.id,
                  let user = users[response.userId] else { return nil }
            return FeedPost(
                id: responseId,
                response: response,
                user: user,
                dropTitle: "Drop",
                dropPromptIcon: "📸",
                isLikedByCurrentUser: response.isLikedBy(userId: currentUserId)
            )
        }
    }

    // MARK: - Private Helpers

    private func fetchUsersMap(ids: [String]) async throws -> [String: UserModel] {
        guard !ids.isEmpty else { return [:] }
        // Firestore `in` query supports up to 30 items per call
        var result: [String: UserModel] = [:]
        let chunks = ids.chunked(into: 10)
        for chunk in chunks {
            let snapshot = try await db.collection(Collections.users)
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments()
            for doc in snapshot.documents {
                if let user = try? doc.data(as: UserModel.self), let uid = user.id {
                    result[uid] = user
                }
            }
        }
        return result
    }

    private func fetchDropsMap(ids: [String]) async throws -> [String: DropModel] {
        guard !ids.isEmpty else { return [:] }
        var result: [String: DropModel] = [:]
        let chunks = ids.chunked(into: 10)
        for chunk in chunks {
            let snapshot = try await db.collection(Collections.drops)
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments()
            for doc in snapshot.documents {
                if let drop = try? doc.data(as: DropModel.self), let did = drop.id {
                    result[did] = drop
                }
            }
        }
        return result
    }
}

// MARK: - Array Chunking Utility
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
