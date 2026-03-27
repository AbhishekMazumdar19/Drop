import Foundation
import FirebaseAuth
import Combine

// MARK: - Auth Errors
enum AuthError: LocalizedError {
    case invalidEmail
    case weakPassword
    case emailAlreadyInUse
    case userNotFound
    case wrongPassword
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidEmail:       return "Please enter a valid email address."
        case .weakPassword:       return "Password must be at least 6 characters."
        case .emailAlreadyInUse:  return "An account with this email already exists."
        case .userNotFound:       return "No account found with this email."
        case .wrongPassword:      return "Incorrect password. Please try again."
        case .unknown(let msg):   return msg
        }
    }
}

// MARK: - AuthService
final class AuthService {

    static let shared = AuthService()
    private init() {}

    // MARK: Current User
    var currentUser: FirebaseAuth.User? { Auth.auth().currentUser }
    var currentUserId: String? { Auth.auth().currentUser?.uid }

    // MARK: Sign Up
    func signUp(email: String, password: String) async throws -> String {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            return result.user.uid
        } catch let error as NSError {
            throw mapError(error)
        }
    }

    // MARK: Sign In
    func signIn(email: String, password: String) async throws -> String {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            return result.user.uid
        } catch let error as NSError {
            throw mapError(error)
        }
    }

    // MARK: Sign Out
    func signOut() throws {
        try Auth.auth().signOut()
    }

    // MARK: Password Reset
    func sendPasswordReset(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }

    // MARK: Auth State Publisher (Combine)
    var authStatePublisher: AnyPublisher<FirebaseAuth.User?, Never> {
        Publishers.AuthStatePublisher().eraseToAnyPublisher()
    }

    // MARK: - Error Mapping
    private func mapError(_ error: NSError) -> AuthError {
        switch AuthErrorCode(rawValue: error.code) {
        case .invalidEmail:             return .invalidEmail
        case .weakPassword:             return .weakPassword
        case .emailAlreadyInUse:        return .emailAlreadyInUse
        case .userNotFound:             return .userNotFound
        case .wrongPassword:            return .wrongPassword
        default:                        return .unknown(error.localizedDescription)
        }
    }
}

// MARK: - Combine Auth Publisher
extension Publishers {
    struct AuthStatePublisher: Publisher {
        typealias Output  = FirebaseAuth.User?
        typealias Failure = Never

        func receive<S: Subscriber>(subscriber: S) where S.Input == Output, S.Failure == Failure {
            let subscription = AuthStateSubscription(subscriber: subscriber)
            subscriber.receive(subscription: subscription)
        }
    }

    final class AuthStateSubscription<S: Subscriber>: Subscription where S.Input == FirebaseAuth.User?, S.Failure == Never {
        private var handle: AuthStateDidChangeListenerHandle?
        private var subscriber: S?

        init(subscriber: S) {
            self.subscriber = subscriber
            handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
                _ = self?.subscriber?.receive(user)
            }
        }

        func request(_ demand: Subscribers.Demand) {}

        func cancel() {
            if let handle = handle {
                Auth.auth().removeStateDidChangeListener(handle)
            }
            subscriber = nil
        }
    }
}
