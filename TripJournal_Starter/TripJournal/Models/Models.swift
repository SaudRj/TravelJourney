import Foundation
import MapKit

/// Represents  a token that is returns when the user authenticates.
struct Token : Codable{
    let accessToken: String
    let tokenType: String
    
    enum CodingKeys: String , CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
    }
}

struct User : Codable{
    let username: String
    let password: String
}
/// Represents a trip.
struct Trip: Identifiable, Sendable, Hashable, Codable, Comparable {
    static func < (lhs: Trip, rhs: Trip) -> Bool {
        return lhs.startDate < rhs.startDate
    }
    
    var id: Int
    var name: String
    var startDate: Date
    var endDate: Date
    var events: [Event]
    
    enum CodingKeys: String , CodingKey {
        case id = ""
        case name = "name"
        case startDate = "start_date"
        case endDate = "end_date"
        case events = "events"
    }
}

/// Represents an event in a trip.
struct Event: Identifiable, Sendable, Hashable, Codable {
    var id: Int
    var name: String
    var note: String?
    var date: Date
    var location: Location?
    var medias: [Media]
    /// i think here needed to set a coding keys since in the fast api it is "transition_from_previous"
    var transitionFromPrevious: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case name = "name"
        case note = "note"
        case date = "date"
        case location = "location"
        case medias = "medias"
        case transitionFromPrevious = "transition_from_previous"
    }
}

/// Represents a location.
struct Location: Sendable, Hashable, Codable {
    var latitude: Double
    var longitude: Double
    var address: String?

    var coordinate: CLLocationCoordinate2D {
        return .init(latitude: latitude, longitude: longitude)
    }
    enum CodingKeys: String , CodingKey {
        case latitude = "latitude"
        case longitude = "longitude"
        case address = "address"
    }
}

/// Represents a media with a URL.
struct Media: Identifiable, Sendable, Hashable, Codable {
    /// in the response of a POST request caption attribute is missing here
    var id: Int
    var url: URL?
}
