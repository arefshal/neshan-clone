import Foundation
import MapKit

class RoutingService {
    let apiKey = "YOUR_API_KEY" // کلید API شما
    
    // دریافت مسیر از Neshan API
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
                    completion(polyline)
                } else {
                    print("No routes found")
                    completion(nil)
                }
            } catch {
                print("Error decoding route response: \(error)")
                completion(nil)
            }
        }
        
        task.resume()
    }
    
    // Decode کردن Polyline برای رسم مسیر روی نقشه
    func decodePolyline(_ encodedPolyline: String) -> MKPolyline {
        let path = encodedPolyline.decodePolyline()
        var coordinates = path.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
        let polyline = MKPolyline(coordinates: &coordinates, count: coordinates.count)
        return polyline
    }
}
