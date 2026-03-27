import Foundation
import FirebaseFirestore

final class CampusService {

    static let shared = CampusService()
    private init() {}

    private let db = Firestore.firestore()
    private var campusesRef: CollectionReference { db.collection(Collections.campuses) }
    private var zonesRef:    CollectionReference { db.collection(Collections.zones) }

    // MARK: - Fetch Campuses

    func fetchCampuses() async throws -> [CampusModel] {
        let snapshot = try await campusesRef.order(by: "name").getDocuments()
        let remote = try snapshot.documents.compactMap { try $0.data(as: CampusModel.self) }
        // Fall back to mock data if Firestore is empty (dev environment)
        return remote.isEmpty ? CampusModel.mock : remote
    }

    // MARK: - Fetch Zones for Campus

    func fetchZones(campusId: String) async throws -> [ZoneModel] {
        let snapshot = try await zonesRef
            .whereField("campusId", isEqualTo: campusId)
            .order(by: "name")
            .getDocuments()

        let remote = try snapshot.documents.compactMap { try $0.data(as: ZoneModel.self) }
        // Fall back to generated defaults
        return remote.isEmpty ? ZoneModel.defaultZones(campusId: campusId) : remote
    }

    // MARK: - Seed Initial Campus Data

    func seedCampuses() async throws {
        let batch = db.batch()
        for campus in CampusModel.mock {
            guard let id = campus.id else { continue }
            let ref = campusesRef.document(id)
            try batch.setData(from: campus, forDocument: ref)
        }
        try await batch.commit()
    }

    // MARK: - Increment Zone Post Count

    func incrementZonePostCount(zoneId: String) async {
        try? await zonesRef.document(zoneId).updateData([
            "postCount": FieldValue.increment(Int64(1))
        ])
    }

    // MARK: - Seed Zones for Campus

    func seedZones(campusId: String) async throws {
        let zones = ZoneModel.defaultZones(campusId: campusId)
        let batch = db.batch()
        for zone in zones {
            guard let id = zone.id else { continue }
            let ref = zonesRef.document(id)
            try batch.setData(from: zone, forDocument: ref)
        }
        try await batch.commit()
    }
}
