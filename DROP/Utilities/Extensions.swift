import SwiftUI
import Foundation

// MARK: - View Extensions

extension View {
    func onFirstAppear(perform action: @escaping () -> Void) -> some View {
        modifier(FirstAppearModifier(action: action))
    }

    func shimmer(active: Bool = true) -> some View {
        modifier(ShimmerModifier(active: active))
    }

    func dropShadow() -> some View {
        shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 4)
    }

    func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) -> some View {
        onTapGesture {
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.impactOccurred()
        }
    }
}

// MARK: - FirstAppearModifier
struct FirstAppearModifier: ViewModifier {
    @State private var hasAppeared = false
    let action: () -> Void

    func body(content: Content) -> some View {
        content.onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true
            action()
        }
    }
}

// MARK: - ShimmerModifier
struct ShimmerModifier: ViewModifier {
    let active: Bool
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        if active {
            content
                .overlay(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .clear,
                            .white.opacity(0.15),
                            .clear
                        ]),
                        startPoint: .init(x: phase - 0.3, y: 0.5),
                        endPoint:   .init(x: phase + 0.3, y: 0.5)
                    )
                )
                .onAppear {
                    withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                        phase = 1.3
                    }
                }
        } else {
            content
        }
    }
}

// MARK: - String Extensions
extension String {
    var isValidEmail: Bool {
        let regex = #"^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: self)
    }

    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }

    func truncated(to limit: Int, trail: String = "...") -> String {
        count > limit ? String(prefix(limit)) + trail : self
    }
}

// MARK: - Date Extensions
extension Date {
    var isToday: Bool { Calendar.current.isDateInToday(self) }
    var isYesterday: Bool { Calendar.current.isDateInYesterday(self) }

    func timeAgoDisplay() -> String {
        let seconds = Int(Date().timeIntervalSince(self))
        switch seconds {
        case 0..<60:        return "just now"
        case 60..<3600:     return "\(seconds / 60)m ago"
        case 3600..<86400:  return "\(seconds / 3600)h ago"
        case 86400..<604800: return "\(seconds / 86400)d ago"
        default:            return "\(seconds / 604800)w ago"
        }
    }

    var shortTime: String {
        formatted(date: .omitted, time: .shortened)
    }

    var dropDateLabel: String {
        if isToday     { return "Today" }
        if isYesterday { return "Yesterday" }
        return formatted(.dateTime.weekday(.wide))
    }
}

// MARK: - TimeInterval Extensions
extension TimeInterval {
    var countdownString: String {
        let total = max(0, Int(self))
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var durationLabel: String {
        let total = max(0, Int(self))
        if total < 60 { return "\(total)s" }
        return "\(total / 60)m \(total % 60)s"
    }
}

// MARK: - Image URL Loading (async)
extension URL {
    static func optional(_ string: String?) -> URL? {
        guard let s = string else { return nil }
        return URL(string: s)
    }
}

// MARK: - Haptic Feedback
struct HapticFeedback {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
