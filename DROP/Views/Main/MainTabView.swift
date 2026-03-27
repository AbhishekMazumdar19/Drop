import SwiftUI

// MARK: - Main Tab View
// The root tabbed interface shown after authentication + onboarding.
// Feed tab is gated: shows LockedFeedView if user hasn't posted today.
struct MainTabView: View {

    @EnvironmentObject private var appState: AppState
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {

            // MARK: Tab 0 — Feed
            feedTab
                .tabItem {
                    Label("Feed", systemImage: selectedTab == 0 ? "flame.fill" : "flame")
                }
                .tag(0)

            // MARK: Tab 1 — Drop (center action)
            DropTabView()
                .environmentObject(appState)
                .tabItem {
                    Label("Drop", systemImage: "camera.aperture")
                }
                .tag(1)

            // MARK: Tab 2 — Campus
            CampusView()
                .environmentObject(appState)
                .tabItem {
                    Label("Campus", systemImage: selectedTab == 2 ? "mappin.and.ellipse" : "mappin")
                }
                .tag(2)

            // MARK: Tab 3 — Messages
            MessagesView()
                .environmentObject(appState)
                .tabItem {
                    Label("Messages", systemImage: selectedTab == 3 ? "message.fill" : "message")
                }
                .badge(appState.unreadMessageCount > 0 ? appState.unreadMessageCount : 0)
                .tag(3)

            // MARK: Tab 4 — Profile
            ProfileView()
                .environmentObject(appState)
                .tabItem {
                    Label("Profile", systemImage: selectedTab == 4 ? "person.fill" : "person")
                }
                .tag(4)
        }
        .tint(Color.dropOrange)
        .preferredColorScheme(.dark)
        // Tab bar styling
        .onAppear { styleTabBar() }
        // One-time deep link routing
        .onReceive(NotificationCenter.default.publisher(for: .navigateToDropTab)) { _ in
            selectedTab = 1
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToFeedTab)) { _ in
            selectedTab = 0
        }
    }

    // MARK: - Feed Tab (gated)
    @ViewBuilder
    private var feedTab: some View {
        if appState.hasPostedToday {
            FeedView()
                .environmentObject(appState)
        } else {
            LockedFeedView()
                .environmentObject(appState)
        }
    }

    // MARK: - Tab Bar Appearance
    private func styleTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1.0)

        // Divider line
        appearance.shadowColor = UIColor.white.withAlphaComponent(0.08)

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
