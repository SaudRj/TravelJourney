import Combine
import Foundation

/// An unimplemented version of the `JournalService`.
class UnimplementedJournalService: JournalService {
    
    //EDIT
    private var token: Token?
    private let isAuthenticatedSubject = CurrentValueSubject<Bool, Never>(false)
    private var trips: [Trip] = []
    
    /// A publisher that can be observed to indicate whether the user is authenticated or not.
    var isAuthenticated: AnyPublisher<Bool, Never> {
        isAuthenticatedSubject.eraseToAnyPublisher()
    }
    
    func helperNetwork<T>(dataToEncode: T, httpMethod: String, domain: String, Path :String?) async throws -> (Data, URLResponse) where T : Encodable
    {
        let encode = try JSONEncoder().encode(dataToEncode)
        let baseURL : String
        
        if let path = Path{
            baseURL = "http://localhost:8000/\(domain)/\(path)"
        }
        else{
            baseURL = "http://localhost:8000/\(domain)"
        }
        
        guard let api = URL(string: baseURL) else { throw URLError(.badURL) }
        var request = URLRequest(url: api)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = httpMethod
        request.httpBody = encode
        //let (data, response) = try await URLSession.shared.data(for: request)
        //return (data, response)
        return try await URLSession.shared.data(for: request)
    }

    func register(username : String, password : String) async throws -> Token {
        
        let createUser : User = User(username: username, password: password)
        
//        let encode = try JSONEncoder().encode(createUser)
//        guard let api =  URL(string: "http://localhost:8000/register")
//        else { throw URLError(.badURL) }
//        var request = URLRequest(url: api)
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.httpMethod = "POST"
//        request.httpBody = encode
        
//         let (data,_) = try await URLSessions.shared.data(for: request)
        
        let (data, _) = try await helperNetwork(dataToEncode: createUser, httpMethod: "POST", domain: "register", Path: nil)
        
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
        
//        let encode = try JSONEncoder().encode(logInUser)
//        guard let api =  URL(string: "http://localhost:8000/token")
//        else { throw URLError(.badURL) }
//        var request = URLRequest(url: api)
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.httpMethod = "POST"
//        request.httpBody = encode
//        
//        let (data, _) = try await URLSession.shared.data(for: request)
        
        let (data, _) = try await helperNetwork(dataToEncode: logInUser, httpMethod: "POST", domain: "token", Path: nil)
        
        let decodeToken = try JSONDecoder().decode(Token.self, from: data)
        self.token = decodeToken
        isAuthenticatedSubject.send(true)
        return decodeToken
        //fatalError("Unimplemented logIn")
    }
    
    func getTrips() async throws -> [Trip] {
        
        guard let api = URL(string: "http://localhost:8000/trips") else { throw URLError(.badURL)}
        let (data, _) = try await URLSession.shared.data(from: api)
        let decodedTrips = try JSONDecoder().decode( [Trip].self, from: data)
        trips = decodedTrips
        return trips
       // fatalError("Unimplemented getTrips")
    }

    func createTrip(with request: TripCreate) async throws -> Trip {
        
        //request coming from parameter
//        let encodedData = try JSONEncoder().encode(request)
//        guard let api = URL(string: "http://localhost:8000/trips") else { throw URLError(.badURL)}
//        var request = URLRequest(url: api)
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.httpMethod = "POST"
//        request.httpBody = encodedData
//        
//        let (data, _) = try await URLSession.shared.data(for: request)
        
        let (data, _) = try await helperNetwork(dataToEncode: request, httpMethod: "POST", domain: "trips", Path: nil)
        
        let decodedData = try JSONDecoder().decode(Trip.self, from: data)
        trips.append(decodedData)
        trips.sort()
        return decodedData

        //fatalError("Unimplemented createTrip")
    }


    func getTrip(withId tripId: Trip.ID) async throws -> Trip {
        
        guard let api = URL(string: "http://localhost:8000/trips/\(tripId)") else { throw URLError(.badURL)}
        let (data, _) = try await URLSession.shared.data(from: api)
        let decodedData = try JSONDecoder().decode(Trip.self, from: data)
        return decodedData
        
        //fatalError("Unimplemented getTrip")
    }

    func updateTrip(withId tripId: Trip.ID, and request: TripUpdate) async throws -> Trip {
        //request coming from parameter
//        let encodedData = try JSONEncoder().encode(request)
//        
//        guard let api = URL(string: "http://localhost:8000/trips/\(tripId)") else { throw URLError(.badURL)}
//        var urlRequest = URLRequest(url: api)
//        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        urlRequest.httpMethod = "PUT"
//        urlRequest.httpBody = encodedData
//        
//        let (data, _) = try await URLSession.shared.data(for: urlRequest)
        
        let (data, _) = try await helperNetwork(dataToEncode: request, httpMethod: "PUT", domain: "trips", Path: "\(tripId)")
        let decodedData = try JSONDecoder().decode(Trip.self, from: data)
        
        //did i did here the update correctly?
        guard let tripIndex = trips.firstIndex(where: { $0.id == tripId }) else {
            throw URLError(.unknown)
        }
        trips[tripIndex] = decodedData
        trips.sort()
        
        return trips[tripId]
        
      //  fatalError("Unimplemented updateTrip")
    }

    func deleteTrip(withId tripId: Trip.ID) async throws {
        
        guard let api = URL(string: "http://localhost:8000/trips/\(tripId)") else { throw URLError(.badURL)}
        var request = URLRequest(url: api)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "DELETE"
        
        let (data, _ ) = try await URLSession.shared.data(for: request)
        
        //how can i delete the trip on the array trips?
        trips.removeAll(where: { $0.id == tripId })
        
        print("item has been delete name: \(data)")
    }

    func createEvent(with request: EventCreate) async throws -> Event {
        //let DataToEncode = Event(from: request)
//        guard let api = URL(string: "http://localhost:8000/events")
//        else {
//            throw URLError(.badURL)
//        }
//        let encodedData = try JSONEncoder().encode(request)
//        
//        var urlRequest = URLRequest(url: api)
//        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        urlRequest.httpMethod = "POST"
//        urlRequest.httpBody = encodedData
//        
//        let (data, _) = try await URLSession.shared.data(for: urlRequest)
        
        let (data, _) = try await helperNetwork(dataToEncode: request, httpMethod: "POST", domain: "events", Path: nil)
        
        let decodedData = try JSONDecoder().decode(Event.self, from: data)
        
        //var AddNewEvent = trips[request.tripId].events
        //AddNewEvent.append(decodedData)
        //trips[request.tripId].events = AddNewEvnt
        
        trips[request.tripId].events.append(decodedData)
        trips[request.tripId].events.sort()
        return decodedData
        
      //  fatalError("Unimplemented createEvent")
    }

    func updateEvent(withId eventId: Event.ID, and request: EventUpdate) async throws -> Event {
        
//        guard let api = URL(string: "http://localhost:8000/events/\(eventId)") 
//        else {
//            throw URLError(.badURL)
//        }
//        let encodedData = try JSONEncoder().encode(request)
//        
//        var urlRequest = URLRequest(url: api)
//        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        urlRequest.httpMethod = "PUT"
//        urlRequest.httpBody = encodedData
//        
//        let (data, _) = try await URLSession.shared.data(for: urlRequest)
        
        let (data, _) = try await helperNetwork(dataToEncode: request, httpMethod: "PUT", domain: "events", Path: "\(eventId)")
        let decodedData = try JSONDecoder().decode(Event.self, from: data)
        
        for tripIndex in trips.indices
        {
            for (eventIndex, event) in trips[tripIndex].events.enumerated() where event.id == eventId
            {
                //did i here did the update correctly?
                trips[tripIndex].events[eventIndex] = decodedData
                trips[tripIndex].events.sort()
                return trips[tripIndex].events[eventIndex]
            }
        }
        
        fatalError("Unimplemented updateEvent")
    }

    func deleteEvent(withId eventId: Event.ID) async throws {
        guard let api = URL(string: "http://localhost:8000/events/\(eventId)")
        else{
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: api)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "DELETE"
        
        let (data, _ ) = try await URLSession.shared.data(for: request)
        
        //how can i delete the Event on the array trips?
        for tripIndex in trips.indices {
            for (eventIndex, event) in trips[tripIndex].events.enumerated() where event.id == eventId {
                trips[tripIndex].events.remove(at: eventIndex)
                return
            }
        }
        
        print("item has been delete name: \(data)")
        
        fatalError("Unimplemented deleteEvent")
    }
    // need to review
    func createMedia(with request: MediaCreate) async throws -> Media {
        
//        guard let api = URL(string: "http://localhost:8000/media")
//                else
//        {
//            throw URLError(.badURL)
//        }
//        let encodedData = try JSONEncoder().encode(request)
//        
//        var urlRequest = URLRequest(url: api)
//        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        urlRequest.httpMethod = "POST"
//        urlRequest.httpBody = encodedData
//        
//        let (data, _) = try await URLSession.shared.data(for: urlRequest)
        
        let (data, _) = try await helperNetwork(dataToEncode: request, httpMethod: "POST", domain: "media", Path: nil)
        let decodedData = try JSONDecoder().decode(Media.self, from: data)
        
        for tripIndex in trips.indices
        {
            for (eventIndex, event) in trips[tripIndex].events.enumerated() where event.id == request.eventId
            {
                trips[tripIndex].events[eventIndex].medias.append(decodedData)
                return decodedData
            }
        }
        
        fatalError("Unimplemented createMedia")
    }

    func deleteMedia(withId mediaId: Media.ID) async throws {
        guard let api = URL(string: "http://localhost:8000/media/\(mediaId)")
        else{
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: api)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "DELETE"
        
        let (data, _ ) = try await URLSession.shared.data(for: request)
        
        //how can i delete the Media on the array trips?
        for tripIndex in trips.indices {
            for eventIndex in trips[tripIndex].events.indices {
                for (mediaIndex, media) in trips[tripIndex].events[eventIndex].medias.enumerated() where media.id == mediaId {
                    trips[tripIndex].events[eventIndex].medias.remove(at: mediaIndex)
                    return
                }
            }
        }
        
        fatalError("Unimplemented deleteMedia")
    }
    

}
//extension Event {
////    init(from create: EventCreate) {
////        id = Int.random(in: 0 ... 1000)
////        name = create.name
////        note = create.note
////        date = create.date
////        location = create.location
////        medias = []
////        transitionFromPrevious = create.transitionFromPrevious
////    }
//    
//    mutating func updateUnImplemented(from update: EventUpdate) {
//        name = update.name
//        note = update.note
//        date = update.date
//        location = update.location
//        transitionFromPrevious = update.transitionFromPrevious
//    }
//}
//
//extension Trip {
////    init(from create: TripCreate) {
////        id = Int.random(in: 0 ... 1000)
////        name = create.name
////        startDate = create.startDate
////        endDate = create.endDate
////        events = []
////    }
//    
//    mutating func updateUnImplemented(from update: TripUpdate) {
//        name = update.name
//        startDate = update.startDate
//        endDate = update.endDate
//    }
//}
