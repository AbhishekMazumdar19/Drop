import SwiftUI

// MARK: - CountdownView
/// Large countdown timer used in the Drop capture screen
struct CountdownView: View {

    let timeRemaining: TimeInterval
    var isGrace: Bool = false

    private var urgency: UrgencyLevel {
        if timeRemaining <= 30  { return .critical }
        if timeRemaining <= 120 { return .warning }
        return .normal
    }

    enum UrgencyLevel { case normal, warning, critical }

    var body: some View {
        VStack(spacing: 4) {
            Text(timeRemaining.countdownString)
                .font(DROPFont.mono(52))
                .foregroundColor(urgencyColor)
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.15), value: timeRemaining)

            Text(isGrace ? "LATE WINDOW CLOSES" : "DROP CLOSES IN")
                .font(DROPFont.label(10))
                .foregroundColor(.dropTextSecondary)
                .tracking(2)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(urgencyColor.opacity(0.08))
        .cornerRadius(Radius.md)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md)
                .strokeBorder(urgencyColor.opacity(0.3), lineWidth: 1)
        )
    }

    private var urgencyColor: Color {
        switch urgency {
        case .normal:   return isGrace ? .dropLate : .white
        case .warning:  return .dropLate
        case .critical: return .dropRed
        }
    }
}

// MARK: - MiniCountdownView
/// Small inline countdown for the feed banner
struct MiniCountdownView: View {
    let timeRemaining: TimeInterval
    var isGrace: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isGrace ? "clock.badge.exclamationmark" : "timer")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(isGrace ? .dropLate : .dropOrange)

            Text(timeRemaining.countdownString)
                .font(.system(size: 13, weight: .black, design: .monospaced))
                .foregroundColor(isGrace ? .dropLate : .white)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        CountdownView(timeRemaining: 270, isGrace: false)
        CountdownView(timeRemaining: 45, isGrace: true)
        MiniCountdownView(timeRemaining: 183)
    }
    .padding()
    .background(Color.dropBlack)
}
