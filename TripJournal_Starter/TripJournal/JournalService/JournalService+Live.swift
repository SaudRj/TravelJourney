import Combine
import Foundation

/// An unimplemented version of the `JournalService`.
class JournalServiceLive: JournalService {
    
    //EDIT
    private var token: Token?
    private var authenticationSubject = CurrentValueSubject<Bool, Never>(false)

    private var trips: [Trip] = []
    
    /// A publisher that can be observed to indicate whether the user is authenticated or not.
    var isAuthenticated: AnyPublisher<Bool, Never> {
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
        
        if "GET" != httpMethod{
            request.httpBody = encode
        }
        
        do{
            return try await URLSession.shared.data(for: request)
        }catch{
            print("ERROR in helper function \(error.localizedDescription)")
            throw error
        }
    }

    func register(username : String, password : String) async throws -> Token {
        
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
    }

    func logOut() {
        token = nil
        DispatchQueue.main.async {
                self.authenticationSubject.send(false)
            }
        print("LOG OUT HERE")
    }
    
    func logIn(username : String, password : String) async throws -> Token {
        
        do{
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
    }
    
    func getTrips() async throws -> [Trip] {
        
        let (data, response) = try await helperNetwork(dataToEncode: Data(), httpMethod: "GET", domain: "trips", Path: nil)
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
        
        let (data,response) = try await helperNetwork(dataToEncode: DataToEncode, httpMethod: "POST", domain: "trips", Path: nil)
        print("CreateTrip response \(response)")
        
        // 401 Unauthorized response
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("Error creating new Trip: \(errorMessage)")
                throw URLError(.userAuthenticationRequired)
            }
        
        
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
    }

    func getTrip(withId tripId: Trip.ID) async throws -> Trip {
        
        let (data,response) = try await helperNetwork(dataToEncode: Data(), httpMethod: "GET", domain: "trips", Path: "\(tripId)")
        print("getTrip response: \(response)")
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do{
            let decodedData = try decoder.decode(Trip.self, from: data)
            return decodedData
        }catch{
            print("Decoding error getTrip func: \(error.localizedDescription)")
            throw error
        }
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
    
        let (data, response) = try await helperNetwork(dataToEncode: DataToEncode, httpMethod: "PUT", domain: "trips", Path: "\(tripId)")
        print("updateTrip Response: \(response)")
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do{
            let decodedData = try decoder.decode(Trip.self, from: data)
            
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
        
    }
    
    
    func deleteTrip(withId tripId: Trip.ID) async throws {
        
        let (data, response) = try await helperNetwork(dataToEncode: Data(), httpMethod: "DELETE", domain: "trips", Path: "\(tripId)")
        print("deleteTrip response: \(response)")
        

        trips.removeAll(where: { $0.id == tripId })
    }

    func createEvent(with request: EventCreate) async throws -> Event {

        let dateFormatter = ISO8601DateFormatter()
        let newDate = dateFormatter.string(from: request.date)
        let DataToEncode : [String: Any] =
        [
            "name" : request.name
            ,"date" : newDate
            ,"note" : request.note ?? ""
            ,"location" :
                [
                    "latitude" : request.location?.latitude ?? 0
                    ,"longitude" : request.location?.longitude ?? 0
                    , "address" : request.location?.address ?? ""
            ]
            ,"transition_from_previous" : request.transitionFromPrevious as Any
            ,"trip_id" : request.tripId
        ]
        
        guard let api = URL(string: "http://localhost:8000/events")
        else {
            throw URLError(.badURL)
        }
        
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
            return decodedData
        }catch{
            print("CREATE EVENT Decoding error \(error)")
            throw error
        }
    }

    func updateEvent(withId eventId: Event.ID, and request: EventUpdate) async throws -> Event {
        
        let (data,response) = try await helperNetwork(dataToEncode: request, httpMethod: "PUT", domain: "events", Path: "\(eventId)")
        print("updateEvent response: \(response)")
        // 401 Unauthorized response
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("Error Update Event: \(errorMessage)")
                throw URLError(.userAuthenticationRequired)
            }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do{
            let decodedData = try decoder.decode(Event.self, from: data)
            
            for tripIndex in trips.indices
            {
                for (eventIndex, event) in trips[tripIndex].events.enumerated() where event.id == eventId
                {
                    trips[tripIndex].events[eventIndex] = decodedData
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
        
        let (data,response) = try await helperNetwork(dataToEncode: Data(), httpMethod: "DELETE", domain: "events", Path: "\(eventId)")
        print("deleteEvent response: \(response)")
        
        // 401 Unauthorized response
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("Error Deleting Event: \(errorMessage)")
                throw URLError(.userAuthenticationRequired)
            }
        
        for tripIndex in trips.indices {
            for (eventIndex, event) in trips[tripIndex].events.enumerated() where event.id == eventId {
                trips[tripIndex].events.remove(at: eventIndex)
                return
            }
        }
        
        print("item has been delete name: \(data)")
        
        fatalError("Unimplemented deleteEvent")
    }

    func createMedia(with request: MediaCreate) async throws -> Media {
        
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
        
        let (data, response) = try await helperNetwork(dataToEncode: Data(), httpMethod: "DELETE", domain: "media", Path: "\(mediaId)")
        print("deleteMedia response: \(response)")
        
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
