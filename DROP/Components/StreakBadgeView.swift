import SwiftUI

// MARK: - StreakBadgeView
struct StreakBadgeView: View {

    let streak: Int
    var size: StreakSize = .medium

    enum StreakSize {
        case small, medium, large

        var iconSize: CGFloat {
            switch self { case .small: 12; case .medium: 16; case .large: 24 }
        }
        var fontSize: CGFloat {
            switch self { case .small: 11; case .medium: 14; case .large: 18 }
        }
        var padding: CGFloat {
            switch self { case .small: 4; case .medium: 6; case .large: 10 }
        }
    }

    var body: some View {
        HStack(spacing: 3) {
            Text("🔥")
                .font(.system(size: size.iconSize))

            Text("\(streak)")
                .font(.system(size: size.fontSize, weight: .black, design: .rounded))
                .foregroundColor(streakColor)
        }
        .padding(.horizontal, size.padding + 4)
        .padding(.vertical, size.padding)
        .background(streakColor.opacity(0.15))
        .overlay(
            Capsule().strokeBorder(streakColor.opacity(0.5), lineWidth: 0.5)
        )
        .clipShape(Capsule())
    }

    private var streakColor: Color {
        if streak >= 14 { return .dropYellow }
        if streak >= 7  { return .dropFire }
        if streak >= 3  { return .dropOrange }
        return .dropTextSecondary
    }
}

// MARK: - OnTimeBadge
struct OnTimeBadge: View {
    let isLate: Bool

    var body: some View {
        Text(isLate ? "LATE" : "ON TIME")
            .font(DROPFont.label(9))
            .foregroundColor(isLate ? .dropLate : .dropOnTime)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background((isLate ? Color.dropLate : Color.dropOnTime).opacity(0.15))
            .overlay(
                Capsule().strokeBorder(isLate ? Color.dropLate : Color.dropOnTime, lineWidth: 0.5)
            )
            .clipShape(Capsule())
    }
}

#Preview {
    VStack(spacing: 16) {
        HStack {
            StreakBadgeView(streak: 1, size: .small)
            StreakBadgeView(streak: 5, size: .medium)
            StreakBadgeView(streak: 14, size: .large)
        }
        HStack {
            OnTimeBadge(isLate: false)
            OnTimeBadge(isLate: true)
        }
    }
    .padding()
    .background(Color.dropBlack)
}
