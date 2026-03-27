import SwiftUI
import UIKit

@MainActor
final class ProfileViewModel: ObservableObject {

    // MARK: - Published
    @Published var user: UserModel?
    @Published var recentPosts: [DropResponseModel] = []
    @Published var isLoading: Bool = false
    @Published var isSaving: Bool = false
    @Published var errorMessage: String?

    // Edit state
    @Published var editDisplayName: String = ""
    @Published var editCourse: String = ""
    @Published var editVibe: VibeOption?
    @Published var editImage: UIImage?
    @Published var isEditing: Bool = false

    @Published var earnedBadges: [BadgeModel] = []

    // MARK: - Services
    private let userService  = UserService.shared
    private let dropService  = DropService.shared
    private let mediaService = MediaUploadService.shared

    // MARK: - Load Profile

    func loadProfile(userId: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            async let userFetch  = userService.fetchUser(id: userId)
            async let postsFetch = dropService.fetchUserResponses(userId: userId)

            let user  = try await userFetch
            let posts = try await postsFetch

            self.user = user
            self.recentPosts = posts
            self.earnedBadges = (user?.badges ?? []).compactMap { BadgeModel.badge(for: $0) }
        } catch {
            errorMessage = "Failed to load profile."
        }
    }

    // MARK: - Start Editing

    func startEditing() {
        guard let user = user else { return }
        editDisplayName = user.displayName
        editCourse      = user.course ?? ""
        editVibe        = user.currentVibe.flatMap { VibeOption(rawValue: $0) }
        editImage       = nil
        isEditing       = true
    }

    // MARK: - Save Edits (called from EditProfileView)

    func saveEdits(
        displayName: String,
        course: String,
        vibe: String?,
        image: UIImage?,
        userId: String,
        appState: AppState
    ) async {
        editDisplayName = displayName
        editCourse = course
        editVibe = vibe.flatMap { VibeOption(rawValue: $0) }
        editImage = image
        isEditing = true
        await saveEdits(userId: userId)
    }

    func saveEdits(userId: String) async {
        let name = editDisplayName.trimmed
        guard !name.isEmpty else {
            errorMessage = "Display name cannot be empty."
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            // Upload new photo if selected
            if let image = editImage {
                let url = try await mediaService.uploadProfileImage(image.preparedForUpload(), userId: userId)
                try await userService.updateProfileImageURL(userId: userId, url: url.absoluteString)
                user?.profileImageURL = url.absoluteString
            }

            // Update fields
            try await userService.updateField(userId: userId, key: "displayName", value: name)
            try await userService.updateField(userId: userId, key: "course", value: editCourse.trimmed)
            if let vibe = editVibe {
                try await userService.updateField(userId: userId, key: "currentVibe", value: vibe.rawValue)
            }

            // Reflect locally
            user?.displayName = name
            user?.course      = editCourse.trimmed.isEmpty ? nil : editCourse.trimmed
            user?.currentVibe = editVibe?.rawValue

            isEditing = false
            HapticFeedback.notification(.success)
        } catch {
            errorMessage = "Failed to save changes."
        }
    }

    // MARK: - Stats

    var onTimePercent: String {
        guard let u = user else { return "—" }
        return String(format: "%.0f%%", u.onTimeRate * 100)
    }

    var statSummary: [(label: String, value: String)] {
        guard let u = user else { return [] }
        return [
            ("Drops", "\(u.totalDrops)"),
            ("Streak", "\(u.streakCount)"),
            ("On Time", onTimePercent),
        ]
    }
}
