import SwiftUI

// MARK: - Onboarding Container (step-based flow)
struct OnboardingContainerView: View {

    @EnvironmentObject private var appState: AppState
    @StateObject private var vm = OnboardingViewModel()

    var startStep: AppScreen.OnboardingStep

    @State private var currentStep: AppScreen.OnboardingStep

    init(startStep: AppScreen.OnboardingStep) {
        self.startStep = startStep
        self._currentStep = State(initialValue: startStep)
    }

    var body: some View {
        ZStack {
            Color.dropBlack.ignoresSafeArea()

            switch currentStep {
            case .welcome:
                WelcomeView { advance(to: .campus) }
                    .transition(stepTransition)

            case .campus:
                CampusPickerOnboardingView(vm: vm) { advance(to: .name) }
                    .transition(stepTransition)

            case .name:
                NameSetupView(vm: vm) { advance(to: .photo) }
                    .transition(stepTransition)

            case .photo:
                ProfilePhotoSetupView(vm: vm) { advance(to: .vibe) }
                    .transition(stepTransition)

            case .vibe:
                VibeSetupView(vm: vm) { advance(to: .firstDrop) }
                    .transition(stepTransition)

            case .firstDrop:
                FirstDropGateView(vm: vm)
                    .transition(stepTransition)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: currentStep)
        .task { await vm.loadCampuses() }
    }

    private var stepTransition: AnyTransition {
        .asymmetric(
            insertion:  .move(edge: .trailing).combined(with: .opacity),
            removal:    .move(edge: .leading).combined(with: .opacity)
        )
    }

    private func advance(to step: AppScreen.OnboardingStep) {
        withAnimation(.easeInOut(duration: 0.35)) {
            currentStep = step
        }
    }
}

// MARK: - Onboarding Step Scaffold
struct OnboardingStepView<Content: View>: View {

    let title: String
    let subtitle: String
    var stepIndex: Int = 0
    var totalSteps: Int = 5
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            // Progress dots
            HStack(spacing: 6) {
                ForEach(0..<totalSteps, id: \.self) { i in
                    Capsule()
                        .fill(i <= stepIndex ? Color.dropOrange : Color.dropTextTertiary)
                        .frame(width: i == stepIndex ? 24 : 8, height: 6)
                        .animation(.dropSnap, value: stepIndex)
                }
                Spacer()
            }
            .padding(.top, 60)
            .padding(.horizontal, 24)

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(DROPFont.display(32))
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(DROPFont.body())
                    .foregroundColor(.dropTextSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 32)

            content()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
