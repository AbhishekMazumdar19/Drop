import SwiftUI

// MARK: - AvatarView
/// User avatar with optional streak ring and size customization
struct AvatarView: View {

    let imageURL: String?
    let displayName: String
    var size: CGFloat = 44
    var showStreakRing: Bool = false
    var streakCount: Int = 0
    var ringColor: Color = .dropOrange

    var body: some View {
        ZStack {
            if showStreakRing && streakCount > 0 {
                Circle()
                    .strokeBorder(
                        LinearGradient.dropFireGradient,
                        lineWidth: size * 0.06
                    )
                    .frame(width: size + size * 0.18, height: size + size * 0.18)
            }

            avatarCircle
        }
    }

    @ViewBuilder
    private var avatarCircle: some View {
        if let urlString = imageURL, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                case .failure, .empty:
                    placeholderCircle
                @unknown default:
                    placeholderCircle
                }
            }
        } else {
            placeholderCircle
        }
    }

    private var placeholderCircle: some View {
        ZStack {
            Circle()
                .fill(LinearGradient.dropFireGradient)
                .frame(width: size, height: size)

            Text(displayName.prefix(1).uppercased())
                .font(DROPFont.headline(size * 0.4))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Preview
#Preview {
    HStack(spacing: 24) {
        AvatarView(imageURL: nil, displayName: "Alex", size: 56, showStreakRing: true, streakCount: 7)
        AvatarView(imageURL: nil, displayName: "Maya", size: 44)
        AvatarView(imageURL: nil, displayName: "J",   size: 32)
    }
    .padding()
    .background(Color.dropBlack)
}
