import SwiftUI

// MARK: - Active Drop Banner (shown in feed when a Drop is live)
struct ActiveDropBannerView: View {

    let drop: DropModel
    @State private var timeRemaining: TimeInterval = 0
    @State private var timer: Timer?
    @State private var pulseScale: CGFloat = 1.0

    var isGrace: Bool { drop.isInGracePeriod }

    var body: some View {
        HStack(spacing: 12) {
            // Live indicator
            ZStack {
                Circle()
                    .fill((isGrace ? Color.dropLate : Color.dropOrange).opacity(0.2))
                    .frame(width: 44, height: 44)
                    .scaleEffect(pulseScale)

                Text(drop.promptIcon)
                    .font(.system(size: 22))
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(isGrace ? "LATE WINDOW" : "DROP IS LIVE")
                        .font(DROPFont.label(9))
                        .foregroundColor(isGrace ? .dropLate : .dropOrange)
                        .tracking(2)

                    Circle()
                        .fill(isGrace ? Color.dropLate : Color.dropOnTime)
                        .frame(width: 5, height: 5)
                }

                Text(drop.prompt)
                    .font(DROPFont.body(13))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }

            Spacer()

            MiniCountdownView(timeRemaining: timeRemaining, isGrace: isGrace)
        }
        .padding(14)
        .background(isGrace ? Color.dropLate.opacity(0.1) : Color.dropOrange.opacity(0.1))
        .cornerRadius(Radius.md)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md)
                .strokeBorder(isGrace ? Color.dropLate.opacity(0.4) : Color.dropOrange.opacity(0.4), lineWidth: 1)
        )
        .onAppear {
            timeRemaining = isGrace ? drop.graceTimeRemaining : drop.timeRemaining
            startTimer()
            startPulse()
        }
        .onDisappear { stopTimer() }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            timeRemaining = max(0, isGrace ? drop.graceTimeRemaining : drop.timeRemaining)
        }
    }

    private func stopTimer() { timer?.invalidate(); timer = nil }

    private func startPulse() {
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            pulseScale = 1.2
        }
    }
}

// MARK: - Drop Tab View (center tab — the primary action)
struct DropTabView: View {

    @EnvironmentObject private var appState: AppState
    @StateObject private var dropVM = DropViewModel()
    @State private var showCapture = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dropBlack.ignoresSafeArea()

                if dropVM.dropPhase == .submitted {
                    submittedView
                } else {
                    dropLobbyView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("DROP")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(LinearGradient.dropFireGradient)
                }
            }
        }
        .fullScreenCover(isPresented: $showCapture) {
            if let drop = appState.activeDrop {
                DropCaptureView(drop: drop, dropVM: dropVM)
                    .environmentObject(appState)
            }
        }
        .task {
            await dropVM.loadActiveDrop(
                campusId: appState.currentUser?.campusId ?? "",
                userId: appState.currentUser?.id ?? ""
            )
        }
        .onChange(of: dropVM.hasSubmitted) { _, submitted in
            if submitted { Task { await appState.didCompleteDropSubmission() } }
        }
    }

    // MARK: - Drop Lobby
    private var dropLobbyView: some View {
        VStack(spacing: 0) {
            Spacer()

            switch dropVM.dropPhase {
            case .live:
                liveDropContent
            case .grace:
                graceDropContent
            case .submitted:
                EmptyView()
            case .expired, .noDrop:
                noDropContent
            }

            Spacer()
        }
    }

    // MARK: - Live Drop
    private var liveDropContent: some View {
        VStack(spacing: 28) {
            if let drop = appState.activeDrop {
                VStack(spacing: 12) {
                    Text(drop.promptIcon)
                        .font(.system(size: 64))

                    Text(drop.title.uppercased())
                        .font(DROPFont.label(11))
                        .foregroundColor(.dropOrange)
                        .tracking(3)

                    Text(drop.prompt)
                        .font(DROPFont.display(28))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    CountdownView(timeRemaining: dropVM.timeRemaining, isGrace: false)
                }

                Button {
                    showCapture = true
                    HapticFeedback.impact(.heavy)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "camera.fill")
                        Text("Drop Now")
                            .font(DROPFont.headline(19))
                    }
                    .foregroundColor(.white)
                    .primaryButton()
                }
                .padding(.horizontal, 32)
            }
        }
    }

    // MARK: - Grace Period
    private var graceDropContent: some View {
        VStack(spacing: 28) {
            if let drop = appState.activeDrop {
                VStack(spacing: 12) {
                    Text("⚠️")
                        .font(.system(size: 56))

                    Text("LATE WINDOW")
                        .font(DROPFont.label(11))
                        .foregroundColor(.dropLate)
                        .tracking(3)

                    Text(drop.prompt)
                        .font(DROPFont.display(24))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    CountdownView(timeRemaining: dropVM.timeRemaining, isGrace: true)

                    Text("Late Drops unlock the feed but don't count toward your streak.")
                        .font(DROPFont.body(13))
                        .foregroundColor(.dropTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                Button {
                    showCapture = true
                    HapticFeedback.impact(.heavy)
                } label: {
                    Text("Late Drop — Unlock Feed")
                        .font(DROPFont.headline(17))
                        .foregroundColor(.white)
                        .primaryButton()
                }
                .padding(.horizontal, 32)
            }
        }
    }

    // MARK: - No Active Drop
    private var noDropContent: some View {
        VStack(spacing: 20) {
            Text("🌐")
                .font(.system(size: 64))

            Text("Campus is quiet")
                .font(DROPFont.display(28))
                .foregroundColor(.white)

            Text("No active Drop right now.\nCheck back soon — campus is always live.")
                .font(DROPFont.body())
                .foregroundColor(.dropTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if dropVM.dropPhase == .expired {
                Text("You missed today's Drop.")
                    .font(DROPFont.body(14))
                    .foregroundColor(.dropRed)
            }
        }
    }

    // MARK: - Already Submitted
    private var submittedView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(LinearGradient.dropFireGradient)

            VStack(spacing: 8) {
                Text("You dropped! 🔥")
                    .font(DROPFont.display(28))
                    .foregroundColor(.white)

                if let user = appState.currentUser {
                    StreakBadgeView(streak: user.streakCount, size: .large)
                }

                Text("Your campus can see your Drop.")
                    .font(DROPFont.body())
                    .foregroundColor(.dropTextSecondary)
                    .multilineTextAlignment(.center)
            }

            if let sub = dropVM.submission {
                AsyncImage(url: URL(string: sub.imageURL)) { phase in
                    if case .success(let img) = phase {
                        img.resizable()
                            .scaledToFill()
                            .frame(width: 200, height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                    }
                }
            }
        }
        .padding()
    }
}
