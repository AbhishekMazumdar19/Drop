import SwiftUI

struct LockedFeedView: View {

    @EnvironmentObject private var appState: AppState
    @State private var showCapture = false
    @State private var pulseAnimation = false

    var body: some View {
        ZStack {
            Color.dropBlack.ignoresSafeArea()

            VStack(spacing: 0) {
                // Blurred ghost feed (creates FOMO)
                blurredGhostFeed
                    .frame(height: UIScreen.main.bounds.height * 0.55)

                // Lock CTA
                lockOverlay
            }
        }
        .fullScreenCover(isPresented: $showCapture) {
            if let drop = appState.activeDrop {
                let dropVM = DropViewModel()
                DropCaptureView(drop: drop, dropVM: dropVM)
                    .environmentObject(appState)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
    }

    // MARK: - Blurred ghost preview
    private var blurredGhostFeed: some View {
        ZStack {
            // Fake blurred post cards
            VStack(spacing: 2) {
                ForEach(0..<4, id: \.self) { i in
                    ghostCard(index: i)
                }
            }
            .blur(radius: 18)

            // Lock overlay gradient
            LinearGradient(
                colors: [
                    Color.dropBlack.opacity(0),
                    Color.dropBlack.opacity(0.5),
                    Color.dropBlack
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private func ghostCard(index: Int) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.dropSurface)
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.dropSurface)
                    .frame(width: 120 + CGFloat(index * 20), height: 12)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.dropSurface)
                    .frame(width: 80, height: 10)
            }

            Spacer()
        }
        .padding(16)
        .background(Color.dropCard)
        .overlay(
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 0)
                    .fill(Color.dropCard)
                    .frame(height: 160)
                    .padding(.top, 4)
                    .opacity(0.3)
            }
        )
        .allowsHitTesting(false)
    }

    // MARK: - Lock CTA
    private var lockOverlay: some View {
        VStack(spacing: 24) {
            // Lock icon with pulse
            ZStack {
                Circle()
                    .fill(Color.dropOrange.opacity(0.12))
                    .frame(width: 90, height: 90)
                    .scaleEffect(pulseAnimation ? 1.15 : 1.0)

                Circle()
                    .fill(Color.dropOrange.opacity(0.2))
                    .frame(width: 70, height: 70)

                Image(systemName: "lock.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(LinearGradient.dropFireGradient)
            }

            VStack(spacing: 8) {
                Text("Drop to unlock your campus")
                    .font(DROPFont.title(24))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("Everyone is posting right now.\nDrop to see what's happening.")
                    .font(DROPFont.body())
                    .foregroundColor(.dropTextSecondary)
                    .multilineTextAlignment(.center)
            }

            // Active drop info
            if let drop = appState.activeDrop, drop.isAcceptingResponses {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Text(drop.promptIcon)
                            .font(.system(size: 20))
                        Text(drop.prompt)
                            .font(DROPFont.body(14))
                            .foregroundColor(.dropTextSecondary)
                            .multilineTextAlignment(.center)
                    }

                    MiniCountdownView(
                        timeRemaining: drop.isInGracePeriod ? drop.graceTimeRemaining : drop.timeRemaining,
                        isGrace: drop.isInGracePeriod
                    )
                }
                .padding(16)
                .background(Color.dropCard)
                .cornerRadius(Radius.md)

                Button {
                    showCapture = true
                    HapticFeedback.impact(.heavy)
                } label: {
                    Text(drop.isInGracePeriod ? "Late Drop — Unlock Feed" : "Drop Now →")
                        .font(DROPFont.headline(17))
                        .foregroundColor(.white)
                        .primaryButton()
                }
            } else {
                VStack(spacing: 8) {
                    Text("No active Drop right now.")
                        .font(DROPFont.body())
                        .foregroundColor(.dropTextSecondary)

                    Text("Check back soon — Drops go live throughout the day.")
                        .font(DROPFont.caption())
                        .foregroundColor(.dropTextTertiary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 40)
    }
}

#Preview {
    let appState = AppState()
    return LockedFeedView()
        .environmentObject(appState)
}
