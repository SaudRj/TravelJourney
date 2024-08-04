import Combine
import Foundation

/// An unimplemented version of the `JournalService`.
class UnimplementedJournalService: JournalService {
    
    //EDIT
    private var token: Token?
    private let isAuthenticatedSubject = CurrentValueSubject<Bool, Never>(false)

    
    /// A publisher that can be observed to indicate whether the user is authenticated or not.
    var isAuthenticated: AnyPublisher<Bool, Never> {
        isAuthenticatedSubject.eraseToAnyPublisher()
    }

    func register(username : String, password : String) async throws -> Token {
        
        let createUser : User = User(username: username, password: password)
        
        let encode = try JSONEncoder().encode(createUser)
        guard let api =  URL(string: "http://localhost:8000/register")
        else { throw URLError(.badURL) }
        var request = URLRequest(url: api)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = encode
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let decodeToken = try JSONDecoder().decode(Token.self, from: data)
        self.token = decodeToken
        return decodeToken
        //fatalError("Unimplemented register")
    }

    func logOut() {
        token = nil
        isAuthenticatedSubject.send(false)
    }
    
    func logIn(username : String, password : String) async throws -> Token {
        let logInUser : User = User(username: username, password: password)
        
        let encode = try JSONEncoder().encode(logInUser)
        guard let api =  URL(string: "http://localhost:8000/register")
        else { throw URLError(.badURL) }
        var request = URLRequest(url: api)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = encode
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let decodeToken = try JSONDecoder().decode(Token.self, from: data)
        self.token = decodeToken
        isAuthenticatedSubject.send(true)
        return decodeToken
        //fatalError("Unimplemented logIn")
    }

    func createTrip(with _: TripCreate) async throws -> Trip {
        fatalError("Unimplemented createTrip")
    }

    func getTrips() async throws -> [Trip] {
        fatalError("Unimplemented getTrips")
    }

    func getTrip(withId _: Trip.ID) async throws -> Trip {
        fatalError("Unimplemented getTrip")
    }

    func updateTrip(withId _: Trip.ID, and _: TripUpdate) async throws -> Trip {
        fatalError("Unimplemented updateTrip")
    }

    func deleteTrip(withId _: Trip.ID) async throws {
        fatalError("Unimplemented deleteTrip")
    }

    func createEvent(with _: EventCreate) async throws -> Event {
        fatalError("Unimplemented createEvent")
    }

    func updateEvent(withId _: Event.ID, and _: EventUpdate) async throws -> Event {
        fatalError("Unimplemented updateEvent")
    }

    func deleteEvent(withId _: Event.ID) async throws {
        fatalError("Unimplemented deleteEvent")
    }

    func createMedia(with _: MediaCreate) async throws -> Media {
        fatalError("Unimplemented createMedia")
    }

    func deleteMedia(withId _: Media.ID) async throws {
        fatalError("Unimplemented deleteMedia")
    }
}
