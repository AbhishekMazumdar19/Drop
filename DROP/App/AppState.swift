import SwiftUI
import FirebaseAuth
import Combine

// MARK: - App Screen States
enum AppScreen: Equatable {
    case splash
    case auth
    case onboarding(OnboardingStep)
    case main

    enum OnboardingStep: Equatable {
        case welcome
        case campus
        case name
        case photo
        case vibe
        case firstDrop
    }
}

// MARK: - AppState (Global State Machine)
@MainActor
final class AppState: ObservableObject {

    // MARK: Navigation
    @Published var screen: AppScreen = .splash

    // MARK: Current User
    @Published var currentUser: UserModel?
    @Published var hasPostedToday: Bool = false

    // MARK: Active Drop
    @Published var activeDrop: DropModel?
    @Published var isDropLive: Bool = false

    // MARK: Messaging
    @Published var unreadMessageCount: Int = 0

    // MARK: Services
    private let authService = AuthService.shared
    private let userService = UserService.shared
    private let dropService = DropService.shared

    private var authHandle: AuthStateDidChangeListenerHandle?

    init() {
        Task { await bootstrap() }
    }

    deinit {
        if let handle = authHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    // MARK: - Bootstrap
    private func bootstrap() async {
        // Brief splash delay for brand moment
        try? await Task.sleep(nanoseconds: 1_500_000_000)

        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor [weak self] in
                await self?.handleAuthChange(firebaseUser: user)
            }
        }
    }

    // MARK: - Auth State Handler
    private func handleAuthChange(firebaseUser: FirebaseAuth.User?) async {
        guard let firebaseUser = firebaseUser else {
            currentUser = nil
            activeDrop = nil
            screen = .auth
            return
        }

        do {
            let user = try await userService.fetchUser(id: firebaseUser.uid)
            self.currentUser = user

            if let user = user, user.hasCompletedOnboarding {
                await refreshActiveDrop()
                await checkTodayParticipation()
                screen = .main
            } else {
                screen = .onboarding(.welcome)
            }
        } catch {
            // Network error — still show auth
            screen = .auth
        }
    }

    // MARK: - Drop State
    func refreshActiveDrop() async {
        do {
            let drop = try await dropService.fetchActiveDrop(campusId: currentUser?.campusId ?? "")
            self.activeDrop = drop
            self.isDropLive = drop?.isCurrentlyActive ?? false
        } catch {
            self.activeDrop = nil
            self.isDropLive = false
        }
    }

    func checkTodayParticipation() async {
        guard let uid = currentUser?.id,
              let dropId = activeDrop?.id else {
            hasPostedToday = false
            return
        }
        do {
            hasPostedToday = try await dropService.hasUserRespondedToDay(userId: uid, dropId: dropId)
        } catch {
            hasPostedToday = false
        }
    }

    // MARK: - Onboarding Completion
    func completeOnboarding() async {
        guard let uid = currentUser?.id else { return }
        do {
            try await userService.updateField(userId: uid, key: "hasCompletedOnboarding", value: true)
            currentUser?.hasCompletedOnboarding = true
        } catch {
            print("[AppState] Failed to mark onboarding complete: \(error)")
        }
        await refreshActiveDrop()
        screen = .main
    }

    // MARK: - Post Drop Completion
    func didCompleteFirstDrop() async {
        hasPostedToday = true
        currentUser?.totalDrops = (currentUser?.totalDrops ?? 0) + 1
        await refreshUser()
    }

    func didCompleteDropSubmission() async {
        hasPostedToday = true
        await refreshUser()
    }

    // MARK: - Refresh
    func refreshUser() async {
        guard let uid = currentUser?.id else { return }
        currentUser = (try? await userService.fetchUser(id: uid)) ?? currentUser
    }

    // MARK: - Sign Out
    func signOut() {
        try? authService.signOut()
        currentUser = nil
        activeDrop = nil
        screen = .auth
    }
}
