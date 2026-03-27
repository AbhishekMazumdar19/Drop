import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

// MARK: - Drop Status
enum DropStatus: String, Codable {
    case upcoming  = "upcoming"
    case active    = "active"
    case grace     = "grace"   // Past window but within grace period
    case expired   = "expired"
}

// MARK: - Drop Model
struct DropModel: Codable, Identifiable {
    @DocumentID var id: String?

    var title: String
    var prompt: String
    var promptIcon: String  // emoji
    var campusId: String

    // Timing (stored as Firestore Timestamps)
    var startsAt: Timestamp
    var endsAt: Timestamp
    var graceEndsAt: Timestamp

    var status: DropStatus
    var allowedMediaType: String    // "image" | "video"

    @ServerTimestamp var createdAt: Timestamp?

    // MARK: - Computed Timing

    var startDate: Date { startsAt.dateValue() }
    var endDate: Date { endsAt.dateValue() }
    var graceEndDate: Date { graceEndsAt.dateValue() }

    var isCurrentlyActive: Bool {
        let now = Date()
        return now >= startDate && now <= endDate && status == .active
    }

    var isInGracePeriod: Bool {
        let now = Date()
        return now > endDate && now <= graceEndDate
    }

    var isAcceptingResponses: Bool {
        isCurrentlyActive || isInGracePeriod
    }

    var isExpired: Bool {
        Date() > graceEndDate
    }

    var timeRemaining: TimeInterval {
        max(0, endDate.timeIntervalSinceNow)
    }

    var graceTimeRemaining: TimeInterval {
        max(0, graceEndDate.timeIntervalSinceNow)
    }

    var computedStatus: DropStatus {
        let now = Date()
        if now < startDate { return .upcoming }
        if now <= endDate  { return .active }
        if now <= graceEndDate { return .grace }
        return .expired
    }

    // MARK: - Factory

    static func makeDemo(prompt: (title: String, prompt: String, icon: String), campusId: String) -> DropModel {
        let now = Date()
        let startTs = Timestamp(date: now)
        let endTs   = Timestamp(date: now.addingTimeInterval(DropConfig.windowDurationSeconds))
        let graceTs = Timestamp(date: now.addingTimeInterval(DropConfig.windowDurationSeconds + DropConfig.gracePeriodSeconds))

        return DropModel(
            id: nil,
            title: prompt.title,
            prompt: prompt.prompt,
            promptIcon: prompt.icon,
            campusId: campusId,
            startsAt: startTs,
            endsAt: endTs,
            graceEndsAt: graceTs,
            status: .active,
            allowedMediaType: "image"
        )
    }
}
