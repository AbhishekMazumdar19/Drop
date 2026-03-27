import SwiftUI

// MARK: - Drop Success View
// Shown after a successful Drop submission — celebrates streak, badges, and identity.
struct DropSuccessView: View {

    @ObservedObject var dropVM: DropViewModel
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var badgesEarned: [BadgeModel] = []
    @State private var appeared = false
    @State private var cardScale: CGFloat = 0.8
    @State private var badgeOffset: CGFloat = 60

    var body: some View {
        ZStack {
            Color.dropBlack.ignoresSafeArea()

            // Background fire pulse
            ZStack {
                Circle()
                    .fill(Color.dropOrange.opacity(0.08))
                    .frame(width: 500, height: 500)
                    .scaleEffect(appeared ? 1.2 : 0.4)
                    .animation(.easeOut(duration: 1.0), value: appeared)

                Circle()
                    .fill(Color.dropFire.opacity(0.04))
                    .frame(width: 700, height: 700)
                    .scaleEffect(appeared ? 1.0 : 0.3)
                    .animation(.easeOut(duration: 1.4), value: appeared)
            }

            VStack(spacing: 32) {
                Spacer()

                // Success icon
                checkmark

                // Identity + streak
                if let user = appState.currentUser {
                    streakSection(user: user)
                }

                // Photo thumbnail
                if let sub = dropVM.submission {
                    photoThumbnail(url: sub.imageURL)
                }

                // Badges earned
                if !badgesEarned.isEmpty {
                    newBadgesSection
                }

                Spacer()

                // CTA
                ctaButton
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .onAppear {
            withAnimation(.dropSpring) { appeared = true }
            loadBadges()
            HapticFeedback.notification(.success)
        }
    }

    // MARK: - Checkmark Animation
    private var checkmark: some View {
        ZStack {
            Circle()
                .fill(LinearGradient.dropFireGradient)
                .frame(width: 96, height: 96)
                .shadow(color: Color.dropOrange.opacity(0.6), radius: 20)
                .scaleEffect(cardScale)

            Image(systemName: "checkmark")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.white)
                .scaleEffect(cardScale)
        }
        .onAppear {
            withAnimation(.dropSpring.delay(0.1)) { cardScale = 1.0 }
        }
    }

    // MARK: - Streak Section
    private func streakSection(user: UserModel) -> some View {
        VStack(spacing: 10) {
            Text("You Dropped! 🔥")
                .font(DROPFont.display(30))
                .foregroundColor(.white)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.2), value: appeared)

            StreakBadgeView(streak: user.streakCount, size: .large)
                .scaleEffect(appeared ? 1 : 0.6)
                .animation(.dropSpring.delay(0.3), value: appeared)

            if let identity = user.dropIdentity, !identity.isEmpty {
                Text(identity)
                    .font(DROPFont.body(14))
                    .foregroundColor(.dropTextSecondary)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut.delay(0.4), value: appeared)
            }
        }
    }

    // MARK: - Photo Thumbnail
    private func photoThumbnail(url: String) -> some View {
        AsyncImage(url: URL(string: url)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 180, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
                    .shadow(color: Color.black.opacity(0.4), radius: 12)
                    .scaleEffect(appeared ? 1 : 0.85)
                    .animation(.dropSpring.delay(0.35), value: appeared)
            case .failure, .empty:
                Color.dropCard
                    .frame(width: 180, height: 180)
                    .cornerRadius(Radius.lg)
            @unknown default:
                EmptyView()
            }
        }
    }

    // MARK: - New Badges Earned
    private var newBadgesSection: some View {
        VStack(spacing: 12) {
            Text("NEW BADGES")
                .font(DROPFont.label(10))
                .foregroundColor(.dropOrange)
                .tracking(3)

            HStack(spacing: 10) {
                ForEach(badgesEarned, id: \.id) { badge in
                    VStack(spacing: 6) {
                        Text(badge.emoji)
                            .font(.system(size: 32))
                        Text(badge.displayName)
                            .font(DROPFont.body(12))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }
                    .frame(width: 90)
                    .padding(12)
                    .background(Color.dropCard)
                    .cornerRadius(Radius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.md)
                            .strokeBorder(badge.tierColor.opacity(0.6), lineWidth: 1)
                    )
                    .offset(y: badgeOffset)
                    .opacity(badgeOffset == 0 ? 1 : 0)
                }
            }
            .onAppear {
                withAnimation(.dropSpring.delay(0.5)) { badgeOffset = 0 }
            }
        }
    }

    // MARK: - CTA
    private var ctaButton: some View {
        Button {
            dismiss()
            HapticFeedback.impact(.medium)
        } label: {
            Text("See the Feed")
                .font(DROPFont.headline(18))
                .foregroundColor(.white)
                .primaryButton()
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut.delay(0.6), value: appeared)
    }

    // MARK: - Load Badges Earned in This Drop
    private func loadBadges() {
        guard let user = appState.currentUser else { return }
        let allBadges = BadgeModel.all
        let earned = user.badges
        badgesEarned = allBadges.filter { earned.contains($0.id) }.prefix(3).map { $0 }
    }
}
