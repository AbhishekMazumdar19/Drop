import SwiftUI

struct SplashView: View {

    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: Double = 0
    @State private var taglineOpacity: Double = 0

    var body: some View {
        ZStack {
            Color.dropBlack.ignoresSafeArea()

            VStack(spacing: 16) {
                // Logo mark — stylized "D" drop shape
                ZStack {
                    Circle()
                        .fill(LinearGradient.dropFireGradient)
                        .frame(width: 88, height: 88)

                    Text("D")
                        .font(.system(size: 52, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                Text("DROP")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .opacity(logoOpacity)

                Text("show up or miss out")
                    .font(DROPFont.body(14))
                    .foregroundColor(.dropTextSecondary)
                    .tracking(2)
                    .opacity(taglineOpacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                logoScale   = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.easeIn(duration: 0.4).delay(0.5)) {
                taglineOpacity = 1.0
            }
        }
    }
}

#Preview {
    SplashView()
}
