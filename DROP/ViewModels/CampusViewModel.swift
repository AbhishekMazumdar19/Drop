import SwiftUI

@MainActor
final class CampusViewModel: ObservableObject {

    @Published var zones: [ZoneModel] = []
    @Published var selectedZone: ZoneModel?
    @Published var zonePosts: [FeedPost] = []
    @Published var isLoadingZones: Bool = false
    @Published var isLoadingPosts: Bool = false
    @Published var totalActiveUsers: Int = 0

    private let campusService = CampusService.shared
    private let feedService   = FeedService.shared

    // MARK: - Load Zones

    func loadZones(campusId: String) async {
        isLoadingZones = true
        defer { isLoadingZones = false }

        zones = (try? await campusService.fetchZones(campusId: campusId)) ?? ZoneModel.defaultZones(campusId: campusId)
        totalActiveUsers = zones.reduce(0) { $0 + $1.activeUserCount }
    }

    // MARK: - Select Zone

    func selectZone(_ zone: ZoneModel, campusId: String, currentUserId: String) async {
        selectedZone = zone
        isLoadingPosts = true
        defer { isLoadingPosts = false }

        zonePosts = (try? await feedService.fetchZonePosts(
            campusId: campusId,
            zoneId: zone.id ?? zone.name,
            currentUserId: currentUserId
        )) ?? []
    }

    // MARK: - Zone color
    func color(for zone: ZoneModel) -> String { zone.colorKey }
}
