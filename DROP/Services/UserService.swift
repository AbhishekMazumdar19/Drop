import Foundation
import FirebaseFirestore

final class UserService {

    static let shared = UserService()
    private init() {}

    private let db = Firestore.firestore()
    private var usersRef: CollectionReference { db.collection(Collections.users) }

    // MARK: - Create User
    func createUser(_ user: UserModel) async throws {
        guard let id = user.id else { throw ServiceError.missingId }
        try usersRef.document(id).setData(from: user)
    }

    // MARK: - Fetch User
    func fetchUser(id: String) async throws -> UserModel? {
        let doc = try await usersRef.document(id).getDocument()
        guard doc.exists else { return nil }
        return try doc.data(as: UserModel.self)
    }

    // MARK: - Update Full User
    func updateUser(_ user: UserModel) async throws {
        guard let id = user.id else { throw ServiceError.missingId }
        try usersRef.document(id).setData(from: user, merge: true)
    }

    // MARK: - Update Single Field
    func updateField(userId: String, key: String, value: Any) async throws {
        try await usersRef.document(userId).updateData([key: value])
    }

    // MARK: - Update FCM Token
    func saveFCMToken(_ token: String, userId: String) async throws {
        try await updateField(userId: userId, key: "fcmToken", value: token)
        try await updateField(userId: userId, key: "lastActiveAt", value: FieldValue.serverTimestamp())
    }

    // MARK: - Update Profile Image
    func updateProfileImageURL(userId: String, url: String) async throws {
        try await updateField(userId: userId, key: "profileImageURL", value: url)
    }

    // MARK: - Award Badges
    func awardBadges(_ badgeIds: [String], toUser userId: String) async throws {
        guard !badgeIds.isEmpty else { return }
        try await usersRef.document(userId).updateData([
            "badges": FieldValue.arrayUnion(badgeIds)
        ])
    }

    // MARK: - Increment Streak
    func incrementStreak(userId: String, isOnTime: Bool) async throws {
        let batch = db.batch()
        let ref = usersRef.document(userId)
        batch.updateData([
            "streakCount": FieldValue.increment(Int64(1)),
            "totalDrops":  FieldValue.increment(Int64(1)),
            "lastActiveAt": FieldValue.serverTimestamp()
        ], forDocument: ref)
        if isOnTime {
            batch.updateData(["onTimeDrops": FieldValue.increment(Int64(1))], forDocument: ref)
        }
        try await batch.commit()
    }

    // MARK: - Break Streak (missed drop)
    func breakStreak(userId: String) async throws {
        try await usersRef.document(userId).updateData(["streakCount": 0])
    }

    // MARK: - Late Drop (total++ but streak unchanged)
    func recordLateResponse(userId: String) async throws {
        try await usersRef.document(userId).updateData([
            "totalDrops": FieldValue.increment(Int64(1)),
            "lastActiveAt": FieldValue.serverTimestamp()
        ])
    }

    // MARK: - Touch lastActiveAt
    func touchActivity(userId: String) async {
        try? await updateField(userId: userId, key: "lastActiveAt", value: FieldValue.serverTimestamp())
    }
}

// MARK: - Service Errors
enum ServiceError: LocalizedError {
    case missingId
    case documentNotFound
    case uploadFailed
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .missingId:         return "Missing document ID."
        case .documentNotFound:  return "Document not found."
        case .uploadFailed:      return "Upload failed. Check your connection."
        case .unknown(let e):    return e.localizedDescription
        }
    }
}
