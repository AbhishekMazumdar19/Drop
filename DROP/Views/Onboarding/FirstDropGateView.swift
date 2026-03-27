import SwiftUI

// MARK: - First Drop Gate (captures first Drop during onboarding)
struct FirstDropGateView: View {

    @ObservedObject var vm: OnboardingViewModel
    @EnvironmentObject private var appState: AppState

    @StateObject private var dropVM = DropViewModel()
    @State private var showCapture = false

    var body: some View {
        ZStack {
            Color.dropBlack.ignoresSafeArea()

            if let activeDrop = appState.activeDrop, activeDrop.isAcceptingResponses {
                liveDropView(drop: activeDrop)
            } else {
                noDropView
            }
        }
        .task {
            if let campusId = vm.selectedCampus?.id {
                await dropVM.loadActiveDrop(
                    campusId: campusId,
                    userId: appState.currentUser?.id ?? ""
                )
            }
        }
        .fullScreenCover(isPresented: $showCapture) {
            if let drop = appState.activeDrop {
                DropCaptureView(drop: drop, dropVM: dropVM)
                    .environmentObject(appState)
                    .onDisappear {
                        if dropVM.hasSubmitted {
                            Task {
                                await saveAndComplete()
                            }
                        }
                    }
            }
        }
    }

    // MARK: - Live Drop Available
    private func liveDropView(drop: DropModel) -> some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 20) {
                // Pulse animation
                ZStack {
                    Circle()
                        .fill(Color.dropOrange.opacity(0.15))
                        .frame(width: 120, height: 120)
                        .scaleEffect(1)

                    Circle()
                        .fill(LinearGradient.dropFireGradient)
                        .frame(width: 88, height: 88)

                    Image(systemName: "camera.fill")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(spacing: 10) {
                    Text("🔥 DROP IS LIVE")
                        .font(DROPFont.label())
                        .foregroundColor(.dropOrange)
                        .tracking(3)

                    Text(drop.title)
                        .font(DROPFont.display(28))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text(drop.prompt)
                        .font(DROPFont.body())
                        .foregroundColor(.dropTextSecondary)
                        .multilineTextAlignment(.center)

                    CountdownView(timeRemaining: drop.timeRemaining, isGrace: drop.isInGracePeriod)
                        .padding(.top, 8)
                }
            }
            .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 12) {
                Text("Complete your first Drop to unlock the feed")
                    .font(DROPFont.body(13))
                    .foregroundColor(.dropTextSecondary)
                    .multilineTextAlignment(.center)

                Button {
                    showCapture = true
                    HapticFeedback.impact(.heavy)
                } label: {
                    HStack(spacing: 10) {
                        Text(drop.promptIcon)
                        Text("Drop Now")
                            .font(DROPFont.headline(19))
                            .foregroundColor(.white)
                    }
                    .primaryButton()
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }

    // MARK: - No Drop Active
    private var noDropView: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 16) {
                Text("⏳")
                    .font(.system(size: 60))

                Text("No active Drop right now")
                    .font(DROPFont.headline())
                    .foregroundColor(.white)

                Text("Drops go live throughout the day.\nCheck back soon or have an admin trigger one.")
                    .font(DROPFont.body())
                    .foregroundColor(.dropTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            Spacer()

            Button {
                Task { await saveAndComplete() }
            } label: {
                Text("Enter the campus →")
                    .font(DROPFont.headline(17))
                    .foregroundColor(.white)
                    .ghostButton()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }

    private func saveAndComplete() async {
        await vm.saveProfile(appState: appState)
        await appState.completeOnboarding()
    }
}
