import Foundation
import UserNotifications
import FirebaseMessaging

final class NotificationService {

    static let shared = NotificationService()
    private init() {}

    // MARK: - Request Permissions
    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    // MARK: - FCM Token
    func currentFCMToken() async -> String? {
        try? await Messaging.messaging().token()
    }

    // MARK: - Local Notification Scheduling (for MVP testing)

    func scheduleDropLiveNotification(dropTitle: String, in seconds: TimeInterval = 0) {
        let content = UNMutableNotificationContent()
        content.title = "🔥 DROP IS LIVE"
        content.body = dropTitle
        content.sound = .defaultCritical
        content.badge = 1
        content.userInfo = ["type": "drop_live"]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
        let request = UNNotificationRequest(
            identifier: "drop_live_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleStreakWarning(streakCount: Int) {
        let content = UNMutableNotificationContent()
        content.title = "⚠️ Streak in danger!"
        content.body = "Your \(streakCount)-day streak is on the line. Drop now to keep it alive."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "streak_warning_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleCommentNotification(fromUser: String, postSnippet: String) {
        let content = UNMutableNotificationContent()
        content.title = "\(fromUser) commented on your Drop"
        content.body = postSnippet
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "comment_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleLikeNotification(fromUser: String) {
        let content = UNMutableNotificationContent()
        content.title = "\(fromUser) liked your Drop 🔥"
        content.body = "Your post is getting attention."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "like_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Clear Badge
    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0) { _ in }
    }
}
