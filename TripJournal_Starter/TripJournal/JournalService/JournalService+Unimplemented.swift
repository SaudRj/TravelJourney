import Combine
import Foundation

/// An unimplemented version of the `JournalService`.
class UnimplementedJournalService: JournalService {
    
    //EDIT
    private var token: Token?
    //private let isAuthenticatedSubject = CurrentValueSubject<Bool, Never>(false)
    private var authenticationSubject = CurrentValueSubject<Bool, Never>(false)

    private var trips: [Trip] = []
    
    /// A publisher that can be observed to indicate whether the user is authenticated or not.
    var isAuthenticated: AnyPublisher<Bool, Never> {
       // isAuthenticatedSubject.eraseToAnyPublisher()
        authenticationSubject.eraseToAnyPublisher()
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
        
        if let tok = token{
            request.setValue("Bearer \(tok.accessToken)", forHTTPHeaderField: "Authorization")
            print("Using token: \(tok.accessToken)")
            } else {
                print("Token is nil")
            }
        request.httpMethod = httpMethod
        request.httpBody = encode
        
        do{
            return try await URLSession.shared.data(for: request)
        }catch{
            print("ERROR in helper function \(error.localizedDescription)")
            throw error
        }
    }

    func register(username : String, password : String) async throws -> Token {
        
        //let createUser : User = User(username: username, password: password)
        let createUser : [String : String] = [ "username" : username, "password" : password]
        let encode = try JSONEncoder().encode(createUser)
        guard let api =  URL(string: "http://localhost:8000/register")
        else { throw URLError(.badURL) }
        var request = URLRequest(url: api)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = encode
        
         let (data,response) = try await URLSession.shared.data(for: request)
        print("Register response: \(response)")
        
        // 401 Unauthorized response
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("Error response in register func: \(errorMessage)")
                throw URLError(.userAuthenticationRequired)
            }
        do{
            let decodeToken = try JSONDecoder().decode(Token.self, from: data)
            self.token = decodeToken
            DispatchQueue.main.async {
                self.authenticationSubject.send(true)
            }
            return decodeToken
        }catch{
            print("Decoding ERROR register func \(error.localizedDescription)")
            throw error
        }
        //fatalError("Unimplemented register")
    }

    func logOut() {
        token = nil
        DispatchQueue.main.async {
                self.authenticationSubject.send(false)
            }
        print("LOG OUT HERE")
    }
    
    func logIn(username : String, password : String) async throws -> Token {
        
        //let logInUser : User = User(username: username, password: password)
        do{
            
        //let encode = try JSONEncoder().encode(logInUser)
            let parameters: [String: String] = [
                "grant_type": "",
                "username": username,
                "password": password,
                "scope": "",
                "client_id": "",
                "client_secret": ""
            ]
            
            // Encode the parameters as application/x-www-form-urlencoded
            let encodedParameters = parameters.map { "\($0.key)=\($0.value)" }
                                               .joined(separator: "&")
                                               .data(using: .utf8)
            
        guard let api =  URL(string: "http://localhost:8000/token")
        else { throw URLError(.badURL) }
        var request = URLRequest(url: api)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = encodedParameters
            
        
        let (data, response) = try await URLSession.shared.data(for: request)

        print("Login Response: \(response)")
          print("Raw response data: \(String(data: data, encoding: .utf8) ?? "No data")")
            
 
            // 401 Unauthorized response
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                    let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                    print("Error in LogIn Func: \(errorMessage)")
                    throw URLError(.userAuthenticationRequired)
                }
            let decodeToken = try JSONDecoder().decode(Token.self, from: data)
            self.token = decodeToken
            
            DispatchQueue.main.async {
                self.authenticationSubject.send(true)
            }
            return decodeToken
        }catch{
            print("Decoding ERROR LOGIN IN \(error.localizedDescription)")
            throw error
        }
        //fatalError("Unimplemented logIn")
    }
    
    func getTrips() async throws -> [Trip] {
        
        guard let api = URL(string: "http://localhost:8000/trips") else { throw URLError(.badURL)}
        var request = URLRequest(url: api)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "GET"
        
        if let tok = token{
            request.setValue("Bearer \(tok.accessToken)", forHTTPHeaderField: "Authorization")
            print("Using token: \(tok.accessToken)")
            } else {
                print("Token is nil")
            }
        
        print("Request Headers: \(request.allHTTPHeaderFields ?? [:])")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        //let (data, response) = try await helperNetwork(dataToEncode: Data(), httpMethod: "GET", domain: "trips", Path: nil)
        print("Getting Trips response: \(response)")
        
        // 401 Unauthorized response
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("Error: \(errorMessage)")
                throw URLError(.userAuthenticationRequired)
            }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do{
            let decodedTrips = try decoder.decode( [Trip].self, from: data)
            trips = decodedTrips
            return trips
        }catch
        {
            print("Decoding error getTrips func: \(error.localizedDescription)")
            throw error
        }
       // fatalError("Unimplemented getTrips")
    }

    
    func createTrip(with request: TripCreate) async throws -> Trip {
        
        print("Request to create trip: \(request)")
        let dateFormatter = ISO8601DateFormatter()
        let startDateString = dateFormatter.string(from: request.startDate)
        let endDateString = dateFormatter.string(from: request.endDate)
        
        let DataToEncode : [String: String] = [
            "name" : request.name
            ,"start_date" : startDateString
            ,"end_date" : endDateString
        ]
        //request coming from parameter
//        let encodedData = try JSONEncoder().encode(DataToEncode)
//        guard let api = URL(string: "http://localhost:8000/trips") else { throw URLError(.badURL)}
//        var request = URLRequest(url: api)
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        
//        if let tok = token{
//            request.setValue("Bearer \(tok.accessToken)", forHTTPHeaderField: "Authorization")
//            print("Using token: \(tok.accessToken)")
//            } else {
//                print("Token is nil")
//            }
//        
//        request.httpMethod = "POST"
//        request.httpBody = encodedData
//
//        
//        let (data, response) = try await URLSession.shared.data(for: request)
        let (data,response) = try await helperNetwork(dataToEncode: DataToEncode, httpMethod: "POST", domain: "trips", Path: nil)
        print("CreateTrip response \(response)")
        
        // 401 Unauthorized response
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("Error creating new Trip: \(errorMessage)")
                throw URLError(.userAuthenticationRequired)
            }
        
       // let (data, response) = try await helperNetwork(dataToEncode: request, httpMethod: "POST", domain: "trips", Path: nil)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do{
            let decodedData = try decoder.decode(Trip.self, from: data)
            trips.append(decodedData)
            trips.sort()
            return decodedData
        }catch{
            print("Decoding error in createTrip: \(error.localizedDescription)")
            throw error
        }

        //fatalError("Unimplemented createTrip")
    }

    func getTrip(withId tripId: Trip.ID) async throws -> Trip {
        
       // guard let api = URL(string: "http://localhost:8000/trips/\(tripId)") else { throw URLError(.badURL)}
        //let (data, _) = try await URLSession.shared.data(from: api)
        let (data,response) = try await helperNetwork(dataToEncode: Data(), httpMethod: "GET", domain: "trips", Path: "\(tripId)")
        print("getTrip response: \(response)")
        do{
            let decodedData = try JSONDecoder().decode(Trip.self, from: data)
            return decodedData
        }catch{
            print("Decoding error getTrip func: \(error.localizedDescription)")
            throw error
        }
        //fatalError("Unimplemented getTrip")
    }

    func updateTrip(withId tripId: Trip.ID, and request: TripUpdate) async throws -> Trip {
        //request coming from parameter
        let dateFormatter = ISO8601DateFormatter()
        let startDateString = dateFormatter.string(from: request.startDate)
        let endDateString = dateFormatter.string(from: request.endDate)
        
        let DataToEncode : [String: String] = [
            "name" : request.name
            ,"start_date" : startDateString
            ,"end_date" : endDateString
        ]
        
//        let encodedData = try JSONEncoder().encode(DataToEncode)
//        
//        guard let api = URL(string: "http://localhost:8000/trips/\(tripId)") else { throw URLError(.badURL)}
//        var urlRequest = URLRequest(url: api)
//        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        urlRequest.httpMethod = "PUT"
//        urlRequest.httpBody = encodedData
//        
//        if let tok = token{
//            urlRequest.setValue("Bearer \(tok.accessToken)", forHTTPHeaderField: "Authorization")
//            print("Using token: \(tok.accessToken)")
//            } else {
//                print("Token is nil")
//            }
//        
//        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        
        
        let (data, response) = try await helperNetwork(dataToEncode: DataToEncode, httpMethod: "PUT", domain: "trips", Path: "\(tripId)")
        print("updateTrip Response: \(response)")
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do{
            let decodedData = try decoder.decode(Trip.self, from: data)
            
            //did i did here the update correctly?
            guard let tripIndex = trips.firstIndex(where: { $0.id == tripId }) else {
                throw URLError(.unknown)
            }
            trips[tripIndex] = decodedData
            trips.sort()
            
            return trips[tripIndex]
        }catch
        {
            print("Decoding error in updateTrip func: \(error.localizedDescription)")
            throw error
        }
        
      //  fatalError("Unimplemented updateTrip")
    }
    
    
    func deleteTrip(withId tripId: Trip.ID) async throws {
        
//        guard let api = URL(string: "http://localhost:8000/trips/\(tripId)") else { throw URLError(.badURL)}
//        var request = URLRequest(url: api)
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.httpMethod = "DELETE"
//        
//        if let tok = token{
//            request.setValue("Bearer \(tok.accessToken)", forHTTPHeaderField: "Authorization")
//            print("Using token: \(tok.accessToken)")
//            } else {
//                print("Token is nil")
//            }
//        
//        let (data, _ ) = try await URLSession.shared.data(for: request)
        
        let (data, response) = try await helperNetwork(dataToEncode: Data(), httpMethod: "DELETE", domain: "trips", Path: "\(tripId)")
        print("deleteTrip response: \(response)")
        
        //how can i delete the trip on the array trips?
        trips.removeAll(where: { $0.id == tripId })
        print("item has been delete name: \(data)")
    }

    func createEvent(with request: EventCreate) async throws -> Event {
        //let DataToEncode = Event(from: request)
        let dateFormatter = ISO8601DateFormatter()
        let newDate = dateFormatter.string(from: request.date)
        let DataToEncode : [String: Any?] =
        [
            "name" : request.name
            ,"date" : newDate
            ,"note" : request.note
            ,"location" : request.location
            ,"transition_from_previous" : request.transitionFromPrevious
            ,"trip_id" : request.tripId
        ]
        
        guard let api = URL(string: "http://localhost:8000/events")
        else {
            throw URLError(.badURL)
        }
        //let encodedData = try JSONEncoder().encode(DataToEncode)
        
        let jsonData = try JSONSerialization.data(withJSONObject: DataToEncode.compactMapValues { $0 })

        var urlRequest = URLRequest(url: api)
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = jsonData
        
        if let tok = token{
            urlRequest.setValue("Bearer \(tok.accessToken)", forHTTPHeaderField: "Authorization")
            print("Using token: \(tok.accessToken)")
            } else {
                print("Token is nil")
            }
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        print("createEvent response: \(response)")
        // 401 Unauthorized response
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("Error creating new Event: \(errorMessage)")
                throw URLError(.userAuthenticationRequired)
            }
        
        //let (data, _) = try await helperNetwork(dataToEncode: request, httpMethod: "POST", domain: "events", Path: nil)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do{
            let decodedData = try decoder.decode(Event.self, from: data)
            

            guard let tripIndex = trips.firstIndex(where: { $0.id == request.tripId }) else {
                throw URLError(.badServerResponse)
                       }
            var NewEventToAddToEvents = trips[tripIndex].events
            NewEventToAddToEvents.append(decodedData)
            trips[tripIndex].events = NewEventToAddToEvents
            //trips[tripIndex].events.sort()
            return decodedData
        }catch{
            print("CREATE EVENT Decoding error \(error)")
            throw error
        }
        
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
//        if let tok = token{
//            urlRequest.setValue("Bearer \(tok.accessToken)", forHTTPHeaderField: "Authorization")
//            print("Using token: \(tok.accessToken)")
//            } else {
//                print("Token is nil")
//            }
//        
//        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        let (data,response) = try await helperNetwork(dataToEncode: request, httpMethod: "PUT", domain: "events", Path: "\(eventId)")
        print("updateEvent response: \(response)")
        // 401 Unauthorized response
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("Error Update Event: \(errorMessage)")
                throw URLError(.userAuthenticationRequired)
            }

        //let (data, _) = try await helperNetwork(dataToEncode: request, httpMethod: "PUT", domain: "events", Path: "\(eventId)")
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do{
            let decodedData = try decoder.decode(Event.self, from: data)
            
            for tripIndex in trips.indices
            {
                for (eventIndex, event) in trips[tripIndex].events.enumerated() where event.id == eventId
                {
                    //did i here did the update correctly?
                    trips[tripIndex].events[eventIndex] = decodedData
                    //trips[tripIndex].events.sort()
                    return trips[tripIndex].events[eventIndex]
                }
            }
        }catch
        {
            print("Update event Decoding error \(error.localizedDescription)")
            throw error
        }
        
        fatalError("Unimplemented updateEvent")
    }

    func deleteEvent(withId eventId: Event.ID) async throws {
//        guard let api = URL(string: "http://localhost:8000/events/\(eventId)")
//        else{
//            throw URLError(.badURL)
//        }
//        
//        var request = URLRequest(url: api)
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.httpMethod = "DELETE"
//        
//        if let tok = token{
//            request.setValue("Bearer \(tok.accessToken)", forHTTPHeaderField: "Authorization")
//            print("Using token: \(tok.accessToken)")
//            } else {
//                print("Token is nil")
//            }
//        
//        let (data, response ) = try await URLSession.shared.data(for: request)
        
        let (data,response) = try await helperNetwork(dataToEncode: Data(), httpMethod: "DELETE", domain: "events", Path: "\(eventId)")
        print("deleteEvent response: \(response)")
        
        // 401 Unauthorized response
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("Error Deleting Event: \(errorMessage)")
                throw URLError(.userAuthenticationRequired)
            }
        
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
//        
//        if let tok = token{
//            urlRequest.setValue("Bearer \(tok.accessToken)", forHTTPHeaderField: "Authorization")
//            print("Using token: \(tok.accessToken)")
//            } else {
//                print("Token is nil")
//            }
//        urlRequest.httpBody = encodedData
//        
//        let (data, _) = try await URLSession.shared.data(for: urlRequest)
        
        let (data, response) = try await helperNetwork(dataToEncode: request, httpMethod: "POST", domain: "media", Path: nil)
        print("createMedia response: \(response)")
        do{
            let decodedData = try JSONDecoder().decode(Media.self, from: data)
            
            for tripIndex in trips.indices
            {
                for (eventIndex, event) in trips[tripIndex].events.enumerated() where event.id == request.eventId
                {
                    trips[tripIndex].events[eventIndex].medias.append(decodedData)
                    return decodedData
                }
            }
        }catch{
            print("Decoding error createMedia: \(error.localizedDescription)")
            throw error
        }
        
        fatalError("Unimplemented createMedia")
    }

    func deleteMedia(withId mediaId: Media.ID) async throws {
//        guard let api = URL(string: "http://localhost:8000/media/\(mediaId)")
//        else{
//            throw URLError(.badURL)
//        }
//        
//        var request = URLRequest(url: api)
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.httpMethod = "DELETE"
//        
//        if let tok = token{
//            request.setValue("Bearer \(tok.accessToken)", forHTTPHeaderField: "Authorization")
//            print("Using token: \(tok.accessToken)")
//            } else {
//                print("Token is nil")
//            }
//        
//        let (data, _ ) = try await URLSession.shared.data(for: request)
        
        let (data, response) = try await helperNetwork(dataToEncode: Data(), httpMethod: "DELETE", domain: "media", Path: "\(mediaId)")
        print("deleteMedia response: \(response)")
        
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
