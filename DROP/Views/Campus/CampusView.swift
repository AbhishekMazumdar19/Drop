import SwiftUI
import MapKit

// MARK: - Campus View
struct CampusView: View {

    @EnvironmentObject private var appState: AppState
    @StateObject private var campusVM = CampusViewModel()
    @State private var selectedZone: ZoneModel?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dropBlack.ignoresSafeArea()

                if campusVM.isLoading {
                    loadingView
                } else {
                    content
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    if let campus = appState.currentUser.flatMap({ _ in CampusModel.mock.first }) {
                        VStack(spacing: 1) {
                            Text(campus.name)
                                .font(DROPFont.headline(16))
                                .foregroundColor(.white)
                            Text("\(campusVM.totalActiveUsers) active now")
                                .font(DROPFont.body(12))
                                .foregroundColor(.dropTextSecondary)
                        }
                    } else {
                        Text("Campus")
                            .font(DROPFont.headline())
                            .foregroundColor(.white)
                    }
                }
            }
            .navigationDestination(for: ZoneModel.self) { zone in
                ZoneDetailView(zone: zone)
                    .environmentObject(appState)
            }
        }
        .task {
            await campusVM.loadZones(campusId: appState.currentUser?.campusId ?? CampusModel.mock[0].id)
        }
    }

    // MARK: - Content
    private var content: some View {
        ScrollView {
            VStack(spacing: 20) {
                campusHeader
                zonesSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .refreshable {
            await campusVM.loadZones(campusId: appState.currentUser?.campusId ?? CampusModel.mock[0].id)
        }
    }

    // MARK: - Campus Header Card
    private var campusHeader: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("CAMPUS MAP")
                        .font(DROPFont.label(10))
                        .foregroundColor(.dropOrange)
                        .tracking(3)

                    Text("Where's everyone dropping?")
                        .font(DROPFont.headline(20))
                        .foregroundColor(.white)
                }
                Spacer()
                Text("🗺️")
                    .font(.system(size: 40))
            }

            // Activity Bar
            HStack(spacing: 0) {
                ForEach(campusVM.zones.prefix(6), id: \.id) { zone in
                    ZoneActivityBar(zone: zone)
                }
            }
            .frame(height: 6)
            .cornerRadius(3)
        }
        .padding(16)
        .background(Color.dropCard)
        .cornerRadius(Radius.lg)
    }

    // MARK: - Zones Grid
    private var zonesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ZONES")
                .font(DROPFont.label(10))
                .foregroundColor(.dropTextSecondary)
                .tracking(3)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(campusVM.zones, id: \.id) { zone in
                    NavigationLink(value: zone) {
                        ZoneCard(zone: zone)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Loading
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .tint(.dropOrange)
            Text("Loading campus…")
                .font(DROPFont.body())
                .foregroundColor(.dropTextSecondary)
        }
    }
}

// MARK: - Zone Activity Bar segment
private struct ZoneActivityBar: View {
    let zone: ZoneModel
    private var zoneColor: Color {
        switch zone.colorKey {
        case "orange": return Color(hex: "#FF5C00")
        case "blue":   return Color(hex: "#3B82F6")
        case "green":  return Color(hex: "#22C55E")
        case "purple": return Color(hex: "#A855F7")
        case "yellow": return Color(hex: "#FFD600")
        case "red":    return Color(hex: "#EF4444")
        default:       return Color(hex: "#6B7280")
        }
    }
    var body: some View {
        zoneColor
            .opacity(zone.activeUserCount > 0 ? 0.8 : 0.2)
            .frame(maxWidth: .infinity)
    }
}

// MARK: - Zone Card
private struct ZoneCard: View {
    let zone: ZoneModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(zone.emoji)
                    .font(.system(size: 32))
                Spacer()
                if zone.activeUserCount > 0 {
                    liveChip
                }
            }

            Text(zone.name)
                .font(DROPFont.headline(16))
                .foregroundColor(.white)

            Text("\(zone.postCount) drops")
                .font(DROPFont.body(13))
                .foregroundColor(.dropTextSecondary)

            if zone.activeUserCount > 0 {
                Text("\(zone.activeUserCount) live")
                    .font(DROPFont.body(12))
                    .foregroundColor(.dropOnTime)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.dropCard)
        .cornerRadius(Radius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg)
                .strokeBorder(zone.activeUserCount > 0 ? Color.dropOrange.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }

    private var liveChip: some View {
        Text("LIVE")
            .font(.system(size: 9, weight: .black))
            .foregroundColor(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Color.dropOnTime)
            .cornerRadius(4)
    }
}

// MARK: - Zone Detail View
struct ZoneDetailView: View {

    let zone: ZoneModel
    @EnvironmentObject private var appState: AppState
    @StateObject private var campusVM = CampusViewModel()
    @StateObject private var feedVM = FeedViewModel()

    var body: some View {
        ZStack {
            Color.dropBlack.ignoresSafeArea()

            if feedVM.isLoading {
                ProgressView().tint(.dropOrange)
            } else if campusVM.zonePosts.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(campusVM.zonePosts, id: \.response.id) { post in
                            NavigationLink {
                                PostDetailView(post: post)
                                    .environmentObject(appState)
                            } label: {
                                PostCard(
                                    post: post,
                                    currentUserId: appState.currentUser?.id ?? "",
                                    onLike: { Task { await feedVM.toggleLike(post: post, userId: appState.currentUser?.id ?? "") } }
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
            }
        }
        .navigationTitle("\(zone.emoji) \(zone.name)")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await campusVM.loadZones(campusId: zone.campusId)
            await campusVM.selectZone(
                zone,
                campusId: zone.campusId,
                currentUserId: appState.currentUser?.id ?? ""
            )
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text(zone.emoji)
                .font(.system(size: 56))
            Text("No Drops here yet")
                .font(DROPFont.headline())
                .foregroundColor(.white)
            Text("Be the first to Drop from \(zone.name).")
                .font(DROPFont.body())
                .foregroundColor(.dropTextSecondary)
        }
    }
}
