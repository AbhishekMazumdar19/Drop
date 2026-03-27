import Foundation
import FirebaseFirestore

struct ZoneModel: Codable, Identifiable {
    @DocumentID var id: String?

    var campusId: String
    var name: String
    var type: String            // ZoneType rawValue
    var postCount: Int
    var activeUserCount: Int

    var zoneType: ZoneType { ZoneType(rawValue: type) ?? .other }
    var emoji: String { zoneType.emoji }

    // Returns a color key used in UI theming
    var colorKey: String {
        switch zoneType {
        case .library:      return "blue"
        case .cafe:         return "orange"
        case .gym:          return "green"
        case .lab:          return "purple"
        case .dorm:         return "yellow"
        case .campusCenter: return "red"
        case .offCampus:    return "gray"
        case .other:        return "gray"
        }
    }

    static func defaultZones(campusId: String) -> [ZoneModel] {
        ZoneType.allCases.map { zoneType in
            ZoneModel(
                id: "\(campusId)_\(zoneType.rawValue.lowercased())",
                campusId: campusId,
                name: zoneType.rawValue,
                type: zoneType.rawValue,
                postCount: Int.random(in: 0...12),
                activeUserCount: Int.random(in: 0...8)
            )
        }
    }
}
