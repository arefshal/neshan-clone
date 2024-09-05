//
//  RoutingService.swift
//  neshan
//
//  Created by Aref on 9/5/24.
//


import Foundation
import MapKit

class RoutingService {
    let apiKey = "service.4ce361741bbd4a2391b15c1004763139"
    
    
    func getRoute(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, completion: @escaping (MKPolyline?) -> Void) {
        let baseUrl = "https://api.neshan.org/v4/direction/no-traffic"
        let originString = "\(origin.latitude),\(origin.longitude)"
        let destinationString = "\(destination.latitude),\(destination.longitude)"
        
        guard let url = URL(string: "\(baseUrl)?origin=\(originString)&destination=\(destinationString)&type=car") else {
            print("Invalid URL")
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.addValue(apiKey, forHTTPHeaderField: "Api-Key")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error fetching route: \(String(describing: error))")
                completion(nil)
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let routeResponse = try decoder.decode(RouteResponse.self, from: data)
                
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
    
  
    func decodePolyline(_ encodedPolyline: String) -> MKPolyline {
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

