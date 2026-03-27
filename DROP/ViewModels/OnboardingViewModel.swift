import SwiftUI
import UIKit

@MainActor
final class OnboardingViewModel: ObservableObject {

    // MARK: - Step data
    @Published var displayName: String = ""
    @Published var selectedCampus: CampusModel?
    @Published var course: String = ""
    @Published var selectedVibe: VibeOption?
    @Published var profileImage: UIImage?
    @Published var profileImageURL: String?

    // MARK: - UI State
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var campuses: [CampusModel] = []

    // MARK: - Services
    private let userService   = UserService.shared
    private let campusService = CampusService.shared
    private let mediaService  = MediaUploadService.shared
    private let authService   = AuthService.shared

    // MARK: - Load Campuses
    func loadCampuses() async {
        campuses = (try? await campusService.fetchCampuses()) ?? CampusModel.mock
    }

    // MARK: - Upload Profile Photo
    func uploadProfilePhoto() async {
        guard let image = profileImage,
              let userId = authService.currentUserId else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let url = try await mediaService.uploadProfileImage(image.preparedForUpload(), userId: userId)
            profileImageURL = url.absoluteString
            try await userService.updateProfileImageURL(userId: userId, url: url.absoluteString)
        } catch {
            errorMessage = "Failed to upload photo. You can add one later."
        }
    }

    // MARK: - Save User Profile
    func saveProfile(appState: AppState) async {
        guard
            let userId = authService.currentUserId,
            let campus = selectedCampus
        else {
            errorMessage = "Please fill in all required fields."
            return
        }

        let name = displayName.trimmed
        guard !name.isEmpty else {
            errorMessage = "Please enter your name."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            // Fetch existing or create new user
            var user = try await userService.fetchUser(id: userId) ?? UserModel.new(
                id: userId,
                email: authService.currentUser?.email ?? "",
                displayName: name,
                campusId: campus.id ?? campus.shortCode,
                campusName: campus.name
            )

            user.displayName = name
            user.campusId    = campus.id ?? campus.shortCode
            user.campusName  = campus.name
            user.course      = course.trimmed.isEmpty ? nil : course.trimmed
            user.currentVibe = selectedVibe?.rawValue
            user.dropIdentity = BadgeEvaluator.computeDropIdentity(user: user)
            if let url = profileImageURL { user.profileImageURL = url }

            try await userService.updateUser(user)

            // Update AppState
            appState.currentUser = user
        } catch {
            errorMessage = "Failed to save profile. Please try again."
        }
    }

    // MARK: - Validate Step
    var canProceedFromName: Bool { !displayName.trimmed.isEmpty }
    var canProceedFromCampus: Bool { selectedCampus != nil }

    func clearError() { errorMessage = nil }
}
