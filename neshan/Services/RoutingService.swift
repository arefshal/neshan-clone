//
//  RoutingService.swift
//  neshan
//
//  Created by Aref on 9/5/24.
//

import Foundation
import MapKit
import CoreLocation

/// A service class responsible for handling routing requests using the Neshan API.
class RoutingService {
    
    // MARK: - Properties
    
    /// The API key used for authenticating requests to the Neshan API.
    private let apiKey = "service.4ce361741bbd4a2391b15c1004763139"
    
    // MARK: - Public Methods
    
    /// Retrieves a route between two points using the Neshan API.
    ///
    /// - Parameters:
    ///   - origin: The starting point of the route.
    ///   - destination: The end point of the route.
    ///   - completion: A closure called with the resulting MKPolyline, or nil if routing failed.
    func getRoute(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, completion: @escaping (MKPolyline?) -> Void) {
        // Construct the base URL for the Neshan routing API
        let baseUrl = "https://api.neshan.org/v4/direction/no-traffic"
        let originString = "\(origin.latitude),\(origin.longitude)"
        let destinationString = "\(destination.latitude),\(destination.longitude)"
        
        // Construct the full URL with query parameters
        guard let url = URL(string: "\(baseUrl)?origin=\(originString)&destination=\(destinationString)&type=car") else {
            print("Invalid URL")
            completion(nil)
            return
        }
        
        // Create and configure the URL request
        var request = URLRequest(url: url)
        request.addValue(apiKey, forHTTPHeaderField: "Api-Key")
        
        // Create and start the data task
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // Handle network errors
            guard let data = data, error == nil else {
                print("Error fetching route: \(String(describing: error))")
                completion(nil)
                return
            }
            
            // Attempt to decode the response
            do {
                let decoder = JSONDecoder()
                let routeResponse = try decoder.decode(RouteResponse.self, from: data)
                
                // Extract and decode the polyline if available
                if let overviewPolyline = routeResponse.routes.first?.overview_polyline.points {
                    let polyline = self.decodePolyline(overviewPolyline)
                    DispatchQueue.main.async {
                        completion(polyline)
                    }
                } else {
                    print("No routes found")
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
            } catch {
                print("Error decoding route response: \(error)")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
        
        task.resume()
    }
    
    // MARK: - Private Methods
    
    /// Decodes an encoded polyline string into an MKPolyline object.
    ///
    /// - Parameter encodedPolyline: The encoded polyline string.
    /// - Returns: An MKPolyline object representing the decoded path.
    private func decodePolyline(_ encodedPolyline: String) -> MKPolyline {
        let path = encodedPolyline.decodedPolyline()
        let coordinates = path.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
        return MKPolyline(coordinates: coordinates, count: coordinates.count)
    }
}

// Add this extension at the end of the file
extension String {
    func decodedPolyline() -> [(latitude: Double, longitude: Double)] {
        var coordinates: [(Double, Double)] = []
        var index = 0
        var lat = 0.0
        var lon = 0.0

        while index < self.count {
            var result = 1
            var shift = 0
            var b: Int
            repeat {
                b = Int(self[self.index(self.startIndex, offsetBy: index)].asciiValue!) - 63
                index += 1
                result += (b & 0x1f) << shift
                shift += 5
            } while b >= 0x20

            lat += Double((result & 1) != 0 ? ~(result >> 1) : (result >> 1))
            
            result = 1
            shift = 0
            repeat {
                b = Int(self[self.index(self.startIndex, offsetBy: index)].asciiValue!) - 63
                index += 1
                result += (b & 0x1f) << shift
                shift += 5
            } while b >= 0x20

            lon += Double((result & 1) != 0 ? ~(result >> 1) : (result >> 1))
            
            coordinates.append((lat * 1e-5, lon * 1e-5))
        }

        return coordinates
    }
}
