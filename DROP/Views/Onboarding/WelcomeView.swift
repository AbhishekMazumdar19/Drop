import SwiftUI

struct WelcomeView: View {

    let onContinue: () -> Void

    @State private var showContent = false

    var body: some View {
        ZStack {
            Color.dropBlack.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient.dropFireGradient)
                            .frame(width: 100, height: 100)

                        Text("D")
                            .font(.system(size: 64, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .scaleEffect(showContent ? 1 : 0.5)
                    .opacity(showContent ? 1 : 0)

                    VStack(spacing: 10) {
                        Text("DROP")
                            .font(.system(size: 48, weight: .black, design: .rounded))
                            .foregroundColor(.white)

                        Text("Your campus is live.")
                            .font(DROPFont.headline(20))
                            .foregroundColor(.dropOrange)

                        Text("Every day, a Drop goes live on your campus.\nYou have minutes to respond.\nMiss it, and the feed stays locked.")
                            .font(DROPFont.body())
                            .foregroundColor(.dropTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                }

                Spacer()

                VStack(spacing: 12) {
                    Button(action: onContinue) {
                        Text("Let's go →")
                            .font(DROPFont.headline(17))
                            .foregroundColor(.white)
                            .primaryButton()
                    }

                    Text("No followers. No curated feeds.\nJust your campus, right now.")
                        .font(DROPFont.caption())
                        .foregroundColor(.dropTextTertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
                .opacity(showContent ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.2)) {
                showContent = true
            }
        }
    }
}

#Preview { WelcomeView(onContinue: {}) }
