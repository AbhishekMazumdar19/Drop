import SwiftUI
import Foundation

@MainActor
final class AuthViewModel: ObservableObject {

    // MARK: - State
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var isSignUp: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Services
    private let authService   = AuthService.shared
    private let userService   = UserService.shared

    // MARK: - Validation
    var isEmailValid: Bool { email.trimmed.isValidEmail }
    var isPasswordValid: Bool { password.count >= 6 }
    var passwordsMatch: Bool { password == confirmPassword }

    var canSubmit: Bool {
        guard isEmailValid && isPasswordValid else { return false }
        if isSignUp { return passwordsMatch && !isLoading }
        return !isLoading
    }

    // MARK: - Sign Up
    func signUp() async {
        guard canSubmit else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            _ = try await authService.signUp(email: email.trimmed, password: password)
            // AppState will handle the state transition via auth listener
        } catch let error as AuthError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Something went wrong. Try again."
        }
    }

    // MARK: - Sign In
    func signIn() async {
        guard isEmailValid && isPasswordValid && !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            _ = try await authService.signIn(email: email.trimmed, password: password)
        } catch let error as AuthError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Something went wrong. Try again."
        }
    }

    // MARK: - Password Reset
    func sendPasswordReset() async {
        guard isEmailValid else {
            errorMessage = "Enter your email first."
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            try await authService.sendPasswordReset(email: email.trimmed)
            errorMessage = "Reset link sent to \(email.trimmed)"
        } catch {
            errorMessage = "Failed to send reset email."
        }
    }

    func clearError() { errorMessage = nil }
}
