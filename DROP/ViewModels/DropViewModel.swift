import SwiftUI
import UIKit

// MARK: - Drop Phase for UI
enum DropPhase {
    case noDrop         // No active drop at all
    case live           // Drop is live right now (capture window)
    case grace          // Drop window closed but grace period open
    case submitted      // User already submitted
    case expired        // Fully expired
}

@MainActor
final class DropViewModel: ObservableObject {

    // MARK: - State
    @Published var activeDrop: DropModel?
    @Published var dropPhase: DropPhase = .noDrop
    @Published var hasSubmitted: Bool = false

    // Capture flow
    @Published var capturedImage: UIImage?
    @Published var selectedZone: ZoneType = .other
    @Published var caption: String = ""
    @Published var selectedVibeTag: VibeTag?

    // Upload progress
    @Published var isSubmitting: Bool = false
    @Published var submitProgress: Double = 0
    @Published var submissionError: String?
    @Published var submission: DropResponseModel?

    // Countdown
    @Published var countdownText: String = "00:00"
    @Published var timeRemaining: TimeInterval = 0

    private var countdownTimer: Timer?

    // MARK: - Services
    private let dropService   = DropService.shared
    private let userService   = UserService.shared
    private let mediaService  = MediaUploadService.shared
    private let badgeEngine   = BadgeEvaluator.self

    // MARK: - Load Active Drop

    func loadActiveDrop(campusId: String, userId: String) async {
        do {
            let drop = try await dropService.fetchCurrentOrGraceDrop(campusId: campusId)
            self.activeDrop = drop

            if let drop = drop {
                self.hasSubmitted = try await dropService.hasUserRespondedToDay(userId: userId, dropId: drop.id ?? "")
                updatePhase(drop: drop)
            } else {
                dropPhase = .noDrop
            }
        } catch {
            dropPhase = .noDrop
        }
    }

    // MARK: - Phase Logic

    private func updatePhase(drop: DropModel) {
        if hasSubmitted {
            dropPhase = .submitted
            stopCountdown()
            return
        }

        let phase = drop.computedStatus
        switch phase {
        case .active:
            dropPhase = .live
            startCountdown(to: drop.endDate)
        case .grace:
            dropPhase = .grace
            startCountdown(to: drop.graceEndDate)
        case .expired:
            dropPhase = .expired
            stopCountdown()
        case .upcoming:
            dropPhase = .noDrop
            stopCountdown()
        }
    }

    // MARK: - Countdown Timer

    private func startCountdown(to date: Date) {
        stopCountdown()
        updateCountdown(to: date)
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateCountdown(to: date)
            }
        }
    }

    private func updateCountdown(to date: Date) {
        timeRemaining = max(0, date.timeIntervalSinceNow)
        countdownText = timeRemaining.countdownString

        if timeRemaining <= 0 {
            stopCountdown()
            // Re-evaluate phase
            if let drop = activeDrop {
                updatePhase(drop: drop)
            }
        }
    }

    private func stopCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }

    // MARK: - Submit Drop

    /// Submit a Drop with the captured image, zone, and vibe tag.
    /// These are passed in directly from DropCaptureView rather than stored as @Published.
    func submitDrop(
        image: UIImage,
        caption: String,
        zone: ZoneType,
        vibe: VibeTag?,
        userId: String,
        appState: AppState
    ) async {
        guard let drop = activeDrop,
              let dropId = drop.id else {
            submissionError = "No active Drop. Please try again."
            return
        }

        isSubmitting = true
        submissionError = nil
        defer { isSubmitting = false }

        do {
            // 1. Upload image
            submitProgress = 0.2
            let imageURL = try await mediaService.uploadDropImage(image.preparedForUpload(), userId: userId)

            submitProgress = 0.5

            // 2. Determine late status
            let isLate = drop.isInGracePeriod

            // 3. Build response
            let zoneId = "\(drop.campusId)_\(zone.rawValue.lowercased().replacingOccurrences(of: " ", with: "_"))"
            let response = DropResponseModel.new(
                dropId: dropId,
                userId: userId,
                campusId: drop.campusId,
                imageURL: imageURL.absoluteString,
                caption: caption.trimmed.isEmpty ? nil : caption.trimmed,
                vibeTag: vibe?.rawValue,
                zoneId: zoneId,
                zoneName: zone.rawValue,
                isLate: isLate
            )

            // 4. Write to Firestore
            let responseId = try await dropService.submitResponse(response)
            submitProgress = 0.75

            // 5. Update user stats
            if isLate {
                try await userService.recordLateResponse(userId: userId)
            } else {
                let streak = appState.currentUser?.streakCount ?? 0
                try await userService.incrementStreak(userId: userId, isOnTime: true)

                // 6. Evaluate + award badges
                if var updatedUser = try await userService.fetchUser(id: userId) {
                    let newBadges = badgeEngine.evaluate(user: updatedUser)
                    if !newBadges.isEmpty {
                        try await userService.awardBadges(newBadges, toUser: userId)
                        updatedUser.badges.append(contentsOf: newBadges)
                    }
                    updatedUser.dropIdentity = badgeEngine.computeDropIdentity(user: updatedUser)
                    try await userService.updateField(userId: userId, key: "dropIdentity", value: updatedUser.dropIdentity ?? "")
                }
            }

            submitProgress = 1.0

            // 7. Update local state
            var savedResponse = response
            savedResponse.id = responseId
            self.submission = savedResponse
            self.hasSubmitted = true
            self.dropPhase = .submitted
            stopCountdown()

            // 8. Update AppState
            await appState.didCompleteDropSubmission()

            HapticFeedback.notification(.success)

        } catch {
            submissionError = error.localizedDescription
            HapticFeedback.notification(.error)
        }
    }

    // MARK: - Reset for new capture
    func resetCapture() {
        capturedImage = nil
        caption = ""
        selectedVibeTag = nil
        submissionError = nil
    }

    deinit {
        countdownTimer?.invalidate()
    }
}
