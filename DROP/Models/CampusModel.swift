import Foundation
import FirebaseFirestore

struct CampusModel: Codable, Identifiable {
    @DocumentID var id: String?

    var name: String
    var city: String
    var country: String
    var shortCode: String       // e.g. "MIT", "UCLA"
    var timezone: String

    static let mock: [CampusModel] = [
        CampusModel(id: "campus_mit",     name: "MIT",                    city: "Cambridge",   country: "US", shortCode: "MIT",    timezone: "America/New_York"),
        CampusModel(id: "campus_stanford", name: "Stanford University",   city: "Stanford",    country: "US", shortCode: "SU",     timezone: "America/Los_Angeles"),
        CampusModel(id: "campus_nyu",     name: "New York University",    city: "New York",    country: "US", shortCode: "NYU",    timezone: "America/New_York"),
        CampusModel(id: "campus_ucl",     name: "University College London", city: "London",  country: "UK", shortCode: "UCL",    timezone: "Europe/London"),
        CampusModel(id: "campus_columbia", name: "Columbia University",   city: "New York",    country: "US", shortCode: "CU",     timezone: "America/New_York"),
        CampusModel(id: "campus_chicago", name: "University of Chicago",  city: "Chicago",     country: "US", shortCode: "UChic",  timezone: "America/Chicago"),
        CampusModel(id: "campus_demo",    name: "Demo Campus",            city: "Anywhere",    country: "US", shortCode: "DEMO",   timezone: "America/New_York"),
    ]
}
