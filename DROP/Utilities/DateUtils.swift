import Foundation

// MARK: - Drop Timing Utilities
enum DateUtils {

    // MARK: Streak Calculation

    /// Determines if a new Drop submission updates the streak
    static func updatesStreak(submission: DropResponseModel, currentStreak: Int) -> (newStreak: Int, isOnTime: Bool) {
        let isOnTime = submission.submissionState == .onTime
        if isOnTime {
            return (currentStreak + 1, true)
        } else {
            // Late submission: doesn't increment streak, doesn't reset it
            return (currentStreak, false)
        }
    }

    // MARK: Feed Cutoff

    static var feedCutoffDate: Date {
        Calendar.current.date(byAdding: .day, value: -DropConfig.feedExpiryDays, to: Date()) ?? Date()
    }

    static func isWithinFeedWindow(_ date: Date) -> Bool {
        date >= feedCutoffDate
    }

    // MARK: Countdown

    static func formattedCountdown(to endDate: Date) -> String {
        let remaining = endDate.timeIntervalSinceNow
        return remaining.countdownString
    }

    // MARK: Drop Phase Description

    static func dropPhaseLabel(for drop: DropModel) -> String {
        switch drop.computedStatus {
        case .upcoming: return "Starts \(drop.startDate.timeAgoDisplay())"
        case .active:   return "Live — \(formattedCountdown(to: drop.endDate)) left"
        case .grace:    return "Late window — \(formattedCountdown(to: drop.graceEndDate)) left"
        case .expired:  return "Expired"
        }
    }

    // MARK: Next Drop Estimate (for UI)

    static func nextDropEstimate() -> String {
        // MVP: returns a friendly string since drops are manually triggered
        "Check back soon"
    }

    // MARK: Relative timestamp for posts

    static func relativeTimestamp(_ date: Date) -> String {
        date.timeAgoDisplay()
    }
}
