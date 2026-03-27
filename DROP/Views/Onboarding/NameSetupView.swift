import SwiftUI

struct NameSetupView: View {
    @ObservedObject var vm: OnboardingViewModel
    let onContinue: () -> Void
    @FocusState private var nameFieldFocused: Bool

    var body: some View {
        OnboardingStepView(
            title: "What's your name?",
            subtitle: "This is how the campus will know you.",
            stepIndex: 2,
            totalSteps: 5
        ) {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    // Name field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Display Name")
                            .font(DROPFont.label())
                            .foregroundColor(.dropTextSecondary)

                        TextField("e.g. Alex Chen", text: $vm.displayName)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .focused($nameFieldFocused)
                            .submitLabel(.next)
                            .padding(16)
                            .background(Color.dropSurface)
                            .cornerRadius(Radius.sm)
                    }

                    // Course (optional)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Program / Course (optional)")
                            .font(DROPFont.label())
                            .foregroundColor(.dropTextSecondary)

                        TextField("e.g. Computer Science", text: $vm.course)
                            .font(DROPFont.body())
                            .foregroundColor(.white)
                            .autocorrectionDisabled()
                            .padding(14)
                            .background(Color.dropSurface)
                            .cornerRadius(Radius.sm)
                    }

                    if let error = vm.errorMessage {
                        Text(error).font(DROPFont.body(13)).foregroundColor(.dropRed)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)

                Spacer()

                Button {
                    guard vm.canProceedFromName else { return }
                    onContinue()
                } label: {
                    Text("Continue")
                        .font(DROPFont.headline(17))
                        .foregroundColor(.white)
                        .primaryButton()
                }
                .disabled(!vm.canProceedFromName)
                .opacity(vm.canProceedFromName ? 1 : 0.4)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .onAppear { nameFieldFocused = true }
    }
}
