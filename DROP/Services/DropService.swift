import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

final class DropService {

    static let shared = DropService()
    private init() {}

    private let db = Firestore.firestore()

    private var dropsRef: CollectionReference { db.collection(Collections.drops) }
    private var responsesRef: CollectionReference { db.collection(Collections.dropResponses) }

    // MARK: - Active Drop

    func fetchActiveDrop(campusId: String) async throws -> DropModel? {
        let snapshot = try await dropsRef
            .whereField("campusId", isEqualTo: campusId)
            .whereField("status", isEqualTo: DropStatus.active.rawValue)
            .order(by: "startsAt", descending: true)
            .limit(to: 1)
            .getDocuments()

        return try snapshot.documents.first.map { try $0.data(as: DropModel.self) }
    }

    /// Also checks grace period drops so late users can still submit
    func fetchCurrentOrGraceDrop(campusId: String) async throws -> DropModel? {
        // Check active first
        if let active = try await fetchActiveDrop(campusId: campusId) {
            return active
        }

        // Check grace period
        let snapshot = try await dropsRef
            .whereField("campusId", isEqualTo: campusId)
            .whereField("status", isEqualTo: DropStatus.grace.rawValue)
            .order(by: "startsAt", descending: true)
            .limit(to: 1)
            .getDocuments()

        return try snapshot.documents.first.map { try $0.data(as: DropModel.self) }
    }

    // MARK: - Create Drop (admin/debug)

    func createDrop(_ drop: DropModel) async throws -> String {
        let docRef = dropsRef.document()
        var newDrop = drop
        newDrop.id = docRef.documentID
        try docRef.setData(from: newDrop)
        return docRef.documentID
    }

    // MARK: - Update Drop Status

    func updateDropStatus(dropId: String, status: DropStatus) async throws {
        try await dropsRef.document(dropId).updateData(["status": status.rawValue])
    }

    // MARK: - Check if User Already Responded

    func hasUserRespondedToDay(userId: String, dropId: String) async throws -> Bool {
        let snapshot = try await responsesRef
            .whereField("userId", isEqualTo: userId)
            .whereField("dropId", isEqualTo: dropId)
            .limit(to: 1)
            .getDocuments()
        return !snapshot.documents.isEmpty
    }

    // MARK: - Submit Drop Response

    func submitResponse(_ response: DropResponseModel) async throws -> String {
        let docRef = responsesRef.document()
        var newResponse = response
        newResponse.id = docRef.documentID
        try docRef.setData(from: newResponse)
        return docRef.documentID
    }

    // MARK: - Fetch Responses for Feed (last 7 days, campus-scoped)

    func fetchFeedResponses(campusId: String, limit: Int = 50) async throws -> [DropResponseModel] {
        let cutoffDate = Calendar.current.date(
            byAdding: .day,
            value: -DropConfig.feedExpiryDays,
            to: Date()
        ) ?? Date()

        let snapshot = try await responsesRef
            .whereField("campusId", isEqualTo: campusId)
            .whereField("createdAt", isGreaterThan: Timestamp(date: cutoffDate))
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()

        return try snapshot.documents.compactMap { try $0.data(as: DropResponseModel.self) }
    }

    // MARK: - Fetch Responses for a Single Drop

    func fetchResponsesForDrop(dropId: String) async throws -> [DropResponseModel] {
        let snapshot = try await responsesRef
            .whereField("dropId", isEqualTo: dropId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        return try snapshot.documents.compactMap { try $0.data(as: DropResponseModel.self) }
    }

    // MARK: - Fetch User's Own Responses

    func fetchUserResponses(userId: String) async throws -> [DropResponseModel] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -DropConfig.feedExpiryDays, to: Date()) ?? Date()

        let snapshot = try await responsesRef
            .whereField("userId", isEqualTo: userId)
            .whereField("createdAt", isGreaterThan: Timestamp(date: cutoffDate))
            .order(by: "createdAt", descending: true)
            .getDocuments()
        return try snapshot.documents.compactMap { try $0.data(as: DropResponseModel.self) }
    }

    // MARK: - Toggle Like

    func toggleLike(responseId: String, userId: String, isLiking: Bool) async throws {
        let ref = responsesRef.document(responseId)
        if isLiking {
            try await ref.updateData([
                "likeCount": FieldValue.increment(Int64(1)),
                "likedByUserIds": FieldValue.arrayUnion([userId])
            ])
        } else {
            try await ref.updateData([
                "likeCount": FieldValue.increment(Int64(-1)),
                "likedByUserIds": FieldValue.arrayRemove([userId])
            ])
        }
    }

    // MARK: - Increment Comment Count

    func incrementCommentCount(responseId: String) async throws {
        try await responsesRef.document(responseId).updateData([
            "commentCount": FieldValue.increment(Int64(1))
        ])
    }

    func decrementCommentCount(responseId: String) async throws {
        try await responsesRef.document(responseId).updateData([
            "commentCount": FieldValue.increment(Int64(-1))
        ])
    }

    // MARK: - Fetch Responses by Zone

    func fetchResponsesForZone(campusId: String, zoneId: String, limit: Int = 20) async throws -> [DropResponseModel] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -DropConfig.feedExpiryDays, to: Date()) ?? Date()

        let snapshot = try await responsesRef
            .whereField("campusId", isEqualTo: campusId)
            .whereField("zoneId", isEqualTo: zoneId)
            .whereField("createdAt", isGreaterThan: Timestamp(date: cutoffDate))
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()

        return try snapshot.documents.compactMap { try $0.data(as: DropResponseModel.self) }
    }
}
