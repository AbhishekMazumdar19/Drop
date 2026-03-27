import SwiftUI

// MARK: - Color Palette
extension Color {
    // Backgrounds
    static let dropBlack    = Color(hex: "#0D0D0D")
    static let dropCard     = Color(hex: "#1A1A1A")
    static let dropSurface  = Color(hex: "#222222")

    // Brand
    static let dropOrange   = Color(hex: "#FF5C00")
    static let dropFire     = Color(hex: "#FF8A00")
    static let dropYellow   = Color(hex: "#FFD600")

    // Semantic
    static let dropOnTime   = Color(hex: "#34C759")
    static let dropLate     = Color(hex: "#FF9F0A")
    static let dropRed      = Color(hex: "#FF3B30")
    static let dropLocked   = Color(hex: "#3A3A3A")

    // Text
    static let dropTextPrimary   = Color.white
    static let dropTextSecondary = Color(hex: "#8A8A8E")
    static let dropTextTertiary  = Color(hex: "#545458")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Gradients
extension LinearGradient {
    static let dropFireGradient = LinearGradient(
        colors: [.dropOrange, .dropFire],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let dropLockedGradient = LinearGradient(
        colors: [.dropBlack, .dropCard, .dropBlack],
        startPoint: .top,
        endPoint: .bottom
    )

    static let dropGoldGradient = LinearGradient(
        colors: [.dropYellow, .dropFire],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let feedBlurGradient = LinearGradient(
        colors: [
            Color.dropBlack.opacity(0),
            Color.dropBlack.opacity(0.7),
            Color.dropBlack
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Typography
struct DROPFont {
    // Display — Headlines
    static func display(_ size: CGFloat = 40) -> Font {
        .system(size: size, weight: .black, design: .rounded)
    }

    // Title
    static func title(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    // Headline
    static func headline(_ size: CGFloat = 18) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    // Body
    static func body(_ size: CGFloat = 15) -> Font {
        .system(size: size, weight: .medium, design: .default)
    }

    // Caption
    static func caption(_ size: CGFloat = 12) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }

    // Label
    static func label(_ size: CGFloat = 11) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    // Mono (countdown timers, stats)
    static func mono(_ size: CGFloat = 48) -> Font {
        .system(size: size, weight: .black, design: .monospaced)
    }
}

// MARK: - Spacing
enum Spacing {
    static let xs: CGFloat   = 4
    static let sm: CGFloat   = 8
    static let md: CGFloat   = 16
    static let lg: CGFloat   = 24
    static let xl: CGFloat   = 32
    static let xxl: CGFloat  = 48
}

// MARK: - Corner Radii
enum Radius {
    static let sm: CGFloat   = 8
    static let md: CGFloat   = 16
    static let lg: CGFloat   = 24
    static let xl: CGFloat   = 32
    static let pill: CGFloat = 999
}

// MARK: - View Modifiers
struct CardStyle: ViewModifier {
    var padding: CGFloat = Spacing.md

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.dropCard)
            .cornerRadius(Radius.md)
    }
}

struct PrimaryButtonStyle: ViewModifier {
    var isLoading: Bool = false

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(LinearGradient.dropFireGradient)
            .cornerRadius(Radius.md)
            .opacity(isLoading ? 0.7 : 1)
    }
}

struct GhostButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md)
                    .strokeBorder(Color.dropTextTertiary, lineWidth: 1)
            )
    }
}

// MARK: - View Extension
extension View {
    func cardStyle(padding: CGFloat = Spacing.md) -> some View {
        modifier(CardStyle(padding: padding))
    }

    func primaryButton(isLoading: Bool = false) -> some View {
        modifier(PrimaryButtonStyle(isLoading: isLoading))
    }

    func ghostButton() -> some View {
        modifier(GhostButtonStyle())
    }

    /// Hides the view conditionally
    func hidden(_ shouldHide: Bool) -> some View {
        opacity(shouldHide ? 0 : 1)
    }
}

// MARK: - Animation
extension Animation {
    static let dropSpring = Animation.spring(response: 0.4, dampingFraction: 0.75)
    static let dropSnap   = Animation.spring(response: 0.25, dampingFraction: 0.9)
}
