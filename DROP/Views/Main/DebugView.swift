import SwiftUI
import FirebaseFirestore

// MARK: - Debug / Admin Panel
// Hidden panel for demo/investor use — seed data, trigger drops, simulate scenarios.
// Access via: tap Profile avatar 5x, or accessible from 'unreadMessageCount' badge long-press.
struct DebugView: View {

    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var statusMessage: String = ""
    @State private var isLoading = false
    @State private var showConfirm = false
    @State private var pendingAction: DebugAction?
    @State private var selectedCampus: CampusModel = CampusModel.mock[0]

    private enum DebugAction: String, Identifiable {
        case triggerDrop = "Trigger Live Drop"
        case triggerGrace = "Trigger Grace Period Drop"
        case resetHasPosted = "Reset hasPostedToday"
        case seedCampuses = "Seed Campuses & Zones"
        case breakStreak = "Break My Streak"
        case simulateStreak7 = "Set Streak to 7"
        case simulateStreak30 = "Set Streak to 30"
        case clearFeed = "Clear Feed Cache"
        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dropBlack.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        warningBanner
                        userSection
                        dropSection
                        dataSection
                        streakSection
                        if !statusMessage.isEmpty { statusBanner }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Debug Panel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.dropOrange)
                }
            }
            .confirmationDialog(
                pendingAction?.rawValue ?? "",
                isPresented: $showConfirm,
                titleVisibility: .visible
            ) {
                Button("Confirm", role: .destructive) {
                    if let action = pendingAction { performAction(action) }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This modifies Firestore data. Use in dev/demo only.")
            }
        }
    }

    // MARK: - Warning Banner
    private var warningBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.dropYellow)
            Text("DEV MODE — Changes affect Firestore")
                .font(DROPFont.body(13))
                .foregroundColor(.dropYellow)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color.dropYellow.opacity(0.08))
        .cornerRadius(Radius.md)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md)
                .strokeBorder(Color.dropYellow.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - User Info
    private var userSection: some View {
        debugSection(title: "CURRENT USER") {
            if let user = appState.currentUser {
                infoRow("ID", value: user.id ?? "—")
                infoRow("Name", value: user.displayName)
                infoRow("Campus", value: user.campusId)
                infoRow("Streak", value: "\(user.streakCount) days")
                infoRow("Drops", value: "\(user.totalDropCount)")
                infoRow("Has Posted Today", value: appState.hasPostedToday ? "YES ✅" : "NO ❌")
                infoRow("Onboarded", value: user.hasCompletedOnboarding ? "YES" : "NO")
            } else {
                Text("No user signed in").font(DROPFont.body()).foregroundColor(.dropTextSecondary)
            }
        }
    }

    // MARK: - Drop Controls
    private var dropSection: some View {
        debugSection(title: "DROP CONTROL") {
            VStack(spacing: 10) {
                Picker("Campus", selection: $selectedCampus) {
                    ForEach(CampusModel.mock, id: \.id) { campus in
                        Text(campus.name).tag(campus)
                    }
                }
                .pickerStyle(.menu)
                .tint(.dropOrange)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color.dropBlack)
                .cornerRadius(Radius.md)

                debugButton("🔴 Trigger Live Drop (5 min)") { confirmAction(.triggerDrop) }
                debugButton("🟡 Trigger Grace Drop (30 min)") { confirmAction(.triggerGrace) }
                debugButton("🔄 Reset hasPostedToday") { confirmAction(.resetHasPosted) }
            }
        }
    }

    // MARK: - Data Seeding
    private var dataSection: some View {
        debugSection(title: "DATA SEEDING") {
            debugButton("🌱 Seed Campuses & Zones") { confirmAction(.seedCampuses) }
        }
    }

    // MARK: - Streak Simulation
    private var streakSection: some View {
        debugSection(title: "STREAK SIMULATION") {
            debugButton("💔 Break My Streak") { confirmAction(.breakStreak) }
            debugButton("🔥 Set Streak → 7") { confirmAction(.simulateStreak7) }
            debugButton("🔥🔥 Set Streak → 30") { confirmAction(.simulateStreak30) }
        }
    }

    // MARK: - Status
    private var statusBanner: some View {
        Text(statusMessage)
            .font(DROPFont.body(14))
            .foregroundColor(.dropOnTime)
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(Color.dropOnTime.opacity(0.08))
            .cornerRadius(Radius.md)
    }

    // MARK: - Helpers
    private func debugSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(DROPFont.label(10))
                .foregroundColor(.dropTextSecondary)
                .tracking(3)

            VStack(spacing: 10) { content() }
                .padding(14)
                .background(Color.dropCard)
                .cornerRadius(Radius.md)
        }
    }

    private func debugButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(DROPFont.body(15))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color.white.opacity(0.05))
                .cornerRadius(Radius.sm)
        }
    }

    private func infoRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(DROPFont.body(13))
                .foregroundColor(.dropTextSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.white)
                .lineLimit(1)
        }
    }

    private func confirmAction(_ action: DebugAction) {
        pendingAction = action
        showConfirm = true
    }

    // MARK: - Action Execution
    private func performAction(_ action: DebugAction) {
        isLoading = true
        Task {
            do {
                switch action {
                case .triggerDrop:
                    let prompt = DropPrompts.all.first ?? (title: "Demo", prompt: "Show us right now.", icon: "📸")
                    let drop = DropModel.makeDemo(prompt: prompt, campusId: selectedCampus.id)
                    try await DropService().createDrop(drop)
                    await appState.refreshActiveDrop()
                    status("Live Drop triggered on \(selectedCampus.name) ✅")

                case .triggerGrace:
                    let prompt = DropPrompts.all.first ?? (title: "Demo", prompt: "Show us right now.", icon: "📸")
                    var drop = DropModel.makeDemo(prompt: prompt, campusId: selectedCampus.id)
                    // Back-date start/end so it's already in grace period
                    let past = Date().addingTimeInterval(-DropConfig.windowDurationSeconds - 1)
                    drop = DropModel(
                        id: nil,
                        title: drop.title,
                        prompt: drop.prompt,
                        promptIcon: drop.promptIcon,
                        campusId: drop.campusId,
                        startsAt: Timestamp(date: past.addingTimeInterval(-DropConfig.windowDurationSeconds)),
                        endsAt: Timestamp(date: past),
                        graceEndsAt: Timestamp(date: Date().addingTimeInterval(DropConfig.gracePeriodSeconds)),
                        status: .grace,
                        allowedMediaType: "image"
                    )
                    try await DropService().createDrop(drop)
                    await appState.refreshActiveDrop()
                    status("Grace Period Drop triggered ✅")

                case .resetHasPosted:
                    await appState.checkTodayParticipation()
                    status("Feed unlock state refreshed ✅")

                case .seedCampuses:
                    try await CampusService().seedCampuses()
                    status("Campuses & zones seeded ✅")

                case .breakStreak:
                    if let userId = appState.currentUser?.id {
                        try await UserService().breakStreak(userId: userId)
                        status("Streak broken 💔")
                    }

                case .simulateStreak7:
                    if let userId = appState.currentUser?.id {
                        try await UserService().updateField(userId: userId, key: "streakCount", value: 7)
                        status("Streak set to 7 🔥")
                    }

                case .simulateStreak30:
                    if let userId = appState.currentUser?.id {
                        try await UserService().updateField(userId: userId, key: "streakCount", value: 30)
                        status("Streak set to 30 🔥🔥")
                    }

                case .clearFeed:
                    status("Feed cache cleared (in-memory only) ✅")
                }
            } catch {
                status("Error: \(error.localizedDescription)")
            }
            isLoading = false
        }
    }

    private func status(_ msg: String) {
        statusMessage = msg
    }
}
