import SwiftUI

struct AuthView: View {

    @State private var isSignUp: Bool = false
    @StateObject private var vm = AuthViewModel()
    @State private var headerOpacity: Double = 0

    var body: some View {
        ZStack {
            Color.dropBlack.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    authHeader

                    // Form
                    authForm

                    // CTA
                    ctaSection

                    // Toggle
                    toggleRow
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.5)) {
                headerOpacity = 1
            }
        }
    }

    // MARK: - Header
    private var authHeader: some View {
        VStack(spacing: 8) {
            Text(isSignUp ? "Join DROP" : "Welcome back")
                .font(DROPFont.display(36))
                .foregroundColor(.white)

            Text(isSignUp
                 ? "Your campus is live. Show up."
                 : "Campus is live. Drop in.")
                .font(DROPFont.body())
                .foregroundColor(.dropTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(headerOpacity)
    }

    // MARK: - Form
    private var authForm: some View {
        VStack(spacing: 16) {
            DROPTextField(
                title: "Email",
                text: $vm.email,
                placeholder: "your@campus.edu",
                keyboardType: .emailAddress,
                icon: "envelope.fill"
            )

            DROPTextField(
                title: "Password",
                text: $vm.password,
                placeholder: "6+ characters",
                isSecure: true,
                icon: "lock.fill"
            )

            if isSignUp {
                DROPTextField(
                    title: "Confirm Password",
                    text: $vm.confirmPassword,
                    placeholder: "Repeat password",
                    isSecure: true,
                    icon: "lock.rotation"
                )
            }

            // Error
            if let error = vm.errorMessage {
                Text(error)
                    .font(DROPFont.body(13))
                    .foregroundColor(.dropRed)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity)
            }
        }
    }

    // MARK: - CTA Buttons
    private var ctaSection: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    if isSignUp { await vm.signUp() }
                    else        { await vm.signIn() }
                }
            } label: {
                ZStack {
                    if vm.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text(isSignUp ? "Create Account" : "Log In")
                            .font(DROPFont.headline(17))
                            .foregroundColor(.white)
                    }
                }
                .primaryButton(isLoading: vm.isLoading)
            }
            .disabled(!vm.canSubmit)

            if !isSignUp {
                Button {
                    Task { await vm.sendPasswordReset() }
                } label: {
                    Text("Forgot password?")
                        .font(DROPFont.body(13))
                        .foregroundColor(.dropTextSecondary)
                }
            }
        }
    }

    // MARK: - Toggle Sign Up / Login
    private var toggleRow: some View {
        Button {
            withAnimation(.dropSnap) {
                isSignUp.toggle()
                vm.errorMessage = nil
                vm.isSignUp = isSignUp
            }
        } label: {
            HStack(spacing: 4) {
                Text(isSignUp ? "Already on campus?" : "Not on campus yet?")
                    .foregroundColor(.dropTextSecondary)
                Text(isSignUp ? "Log In" : "Sign Up")
                    .foregroundColor(.dropOrange)
                    .bold()
            }
            .font(DROPFont.body(14))
        }
    }
}

// MARK: - DROPTextField Component
struct DROPTextField: View {
    let title: String
    @Binding var text: String
    var placeholder: String = ""
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var icon: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(DROPFont.label())
                .foregroundColor(.dropTextSecondary)
                .tracking(0.5)

            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.dropTextTertiary)
                        .frame(width: 18)
                }

                if isSecure {
                    SecureField(placeholder, text: $text)
                        .textContentType(.password)
                        .font(DROPFont.body())
                        .foregroundColor(.white)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .font(DROPFont.body())
                        .foregroundColor(.white)
                }
            }
            .padding(14)
            .background(Color.dropSurface)
            .cornerRadius(Radius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.sm)
                    .strokeBorder(Color.dropTextTertiary.opacity(0.4), lineWidth: 1)
            )
        }
    }
}

#Preview {
    AuthView()
}
