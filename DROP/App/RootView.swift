import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ZStack {
            Color.dropBlack.ignoresSafeArea()

            switch appState.screen {
            case .splash:
                SplashView()
                    .transition(.opacity)

            case .auth:
                AuthView()
                    .transition(.opacity)

            case .onboarding(let step):
                OnboardingContainerView(startStep: step)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))

            case .main:
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: appState.screen)
    }
}
