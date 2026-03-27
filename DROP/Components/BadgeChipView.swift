import SwiftUI

// MARK: - BadgeChipView
/// Compact badge pill shown on profile and feed cards
struct BadgeChipView: View {

    let badgeId: String
    var compact: Bool = false

    private var badge: BadgeModel? { BadgeModel.badge(for: badgeId) }

    var body: some View {
        if let badge = badge {
            HStack(spacing: 4) {
                Text(badge.emoji)
                    .font(.system(size: compact ? 11 : 13))

                if !compact {
                    Text(badge.displayName)
                        .font(DROPFont.label(11))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, compact ? 6 : 10)
            .padding(.vertical, compact ? 3 : 5)
            .background(badge.tierColor.opacity(0.25))
            .overlay(
                Capsule().strokeBorder(badge.tierColor.opacity(0.6), lineWidth: 0.5)
            )
            .clipShape(Capsule())
        }
    }
}

// MARK: - BadgeGridView
/// Grid of badge chips for profile badge display
struct BadgeGridView: View {

    let badges: [BadgeModel]
    var columns: Int = 2

    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: columns),
            spacing: 8
        ) {
            ForEach(badges) { badge in
                HStack(spacing: 8) {
                    Text(badge.emoji)
                        .font(.system(size: 20))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(badge.displayName)
                            .font(DROPFont.caption(12))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text(badge.description)
                            .font(DROPFont.caption(10))
                            .foregroundColor(.dropTextSecondary)
                            .lineLimit(2)
                    }
                    Spacer()
                }
                .padding(10)
                .background(badge.tierColor.opacity(0.12))
                .cornerRadius(Radius.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.sm)
                        .strokeBorder(badge.tierColor.opacity(0.3), lineWidth: 0.5)
                )
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack {
            BadgeChipView(badgeId: BadgeID.weekWarrior.rawValue)
            BadgeChipView(badgeId: BadgeID.nightOwl.rawValue)
            BadgeChipView(badgeId: BadgeID.alwaysOnTime.rawValue, compact: true)
        }

        BadgeGridView(badges: BadgeModel.all.prefix(4).map { $0 })
    }
    .padding()
    .background(Color.dropBlack)
}
