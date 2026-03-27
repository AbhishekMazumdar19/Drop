import Foundation
import SwiftUI

// MARK: - Badge Definition
struct BadgeModel: Identifiable {
    let id: String          // BadgeID rawValue
    let displayName: String
    let emoji: String
    let description: String
    let tier: BadgeTier

    enum BadgeTier: Int {
        case bronze = 1
        case silver = 2
        case gold   = 3
    }

    var tierColor: Color {
        switch tier {
        case .bronze: return Color(hex: "#CD7F32")
        case .silver: return Color.gray
        case .gold:   return Color(hex: "#FFD700")
        }
    }

    // MARK: - All Badge Definitions
    static let all: [BadgeModel] = [
        BadgeModel(
            id: BadgeID.firstDrop.rawValue,
            displayName: BadgeID.firstDrop.displayName,
            emoji: BadgeID.firstDrop.emoji,
            description: "Completed your first ever Drop. Welcome.",
            tier: .bronze
        ),
        BadgeModel(
            id: BadgeID.streakStarter.rawValue,
            displayName: BadgeID.streakStarter.displayName,
            emoji: BadgeID.streakStarter.emoji,
            description: "Kept a streak going for 3 days straight.",
            tier: .bronze
        ),
        BadgeModel(
            id: BadgeID.alwaysOnTime.rawValue,
            displayName: BadgeID.alwaysOnTime.displayName,
            emoji: BadgeID.alwaysOnTime.emoji,
            description: "10 consecutive on-time Drops. Never late.",
            tier: .silver
        ),
        BadgeModel(
            id: BadgeID.weekWarrior.rawValue,
            displayName: BadgeID.weekWarrior.displayName,
            emoji: BadgeID.weekWarrior.emoji,
            description: "Posted every single day for a full week.",
            tier: .silver
        ),
        BadgeModel(
            id: BadgeID.dropKing.rawValue,
            displayName: BadgeID.dropKing.displayName,
            emoji: BadgeID.dropKing.emoji,
            description: "30-day streak. The campus legend.",
            tier: .gold
        ),
        BadgeModel(
            id: BadgeID.nightOwl.rawValue,
            displayName: BadgeID.nightOwl.displayName,
            emoji: BadgeID.nightOwl.emoji,
            description: "Dropped after midnight three times.",
            tier: .bronze
        ),
        BadgeModel(
            id: BadgeID.chaosAgent.rawValue,
            displayName: BadgeID.chaosAgent.displayName,
            emoji: BadgeID.chaosAgent.emoji,
            description: "Your Drop posts are unpredictable. We respect it.",
            tier: .silver
        ),
        BadgeModel(
            id: BadgeID.lateMerchant.rawValue,
            displayName: BadgeID.lateMerchant.displayName,
            emoji: BadgeID.lateMerchant.emoji,
            description: "Submitted late 5 times but never missed. You do you.",
            tier: .bronze
        ),
        BadgeModel(
            id: BadgeID.ghostMode.rawValue,
            displayName: BadgeID.ghostMode.displayName,
            emoji: BadgeID.ghostMode.emoji,
            description: "Missed a Drop and broke your streak. Ghost.",
            tier: .bronze
        ),
        BadgeModel(
            id: BadgeID.consistentGrind.rawValue,
            displayName: BadgeID.consistentGrind.displayName,
            emoji: BadgeID.consistentGrind.emoji,
            description: "Posted on-time for 14 consecutive days.",
            tier: .gold
        ),
    ]

    static func badge(for id: String) -> BadgeModel? {
        all.first { $0.id == id }
    }
}

// MARK: - Badge Rules Engine
struct BadgeEvaluator {
    /// Evaluate which new badges a user should earn given their current stats
    static func evaluate(user: UserModel) -> [String] {
        var newBadges: [String] = []

        let existing = Set(user.badges)

        // First Drop
        if user.totalDrops >= 1 && !existing.contains(BadgeID.firstDrop.rawValue) {
            newBadges.append(BadgeID.firstDrop.rawValue)
        }

        // Streak Starter (3-day streak)
        if user.streakCount >= 3 && !existing.contains(BadgeID.streakStarter.rawValue) {
            newBadges.append(BadgeID.streakStarter.rawValue)
        }

        // Week Warrior (7-day streak)
        if user.streakCount >= 7 && !existing.contains(BadgeID.weekWarrior.rawValue) {
            newBadges.append(BadgeID.weekWarrior.rawValue)
        }

        // Drop King (30-day streak)
        if user.streakCount >= 30 && !existing.contains(BadgeID.dropKing.rawValue) {
            newBadges.append(BadgeID.dropKing.rawValue)
        }

        // Always On Time (10 total on-time with >80% rate)
        if user.onTimeDrops >= 10 && user.onTimeRate >= 0.8 && !existing.contains(BadgeID.alwaysOnTime.rawValue) {
            newBadges.append(BadgeID.alwaysOnTime.rawValue)
        }

        // Consistent Grinder (14-day streak + on-time)
        if user.streakCount >= 14 && !existing.contains(BadgeID.consistentGrind.rawValue) {
            newBadges.append(BadgeID.consistentGrind.rawValue)
        }

        return newBadges
    }

    /// Compute Drop Identity based on behavior
    static func computeDropIdentity(user: UserModel) -> String {
        if user.streakCount >= 14 { return "Consistent Grinder" }
        if user.streakCount >= 7  { return "Week Warrior" }
        if user.onTimeRate < 0.4 && user.totalDrops > 3 { return "Late Merchant" }
        if user.onTimeRate >= 0.9 && user.totalDrops >= 5 { return "Always On Point" }
        if user.totalDrops <= 1  { return "Fresh Drop" }
        if user.streakCount == 0 { return "Ghost Mode" }
        return "Campus Native"
    }
}
