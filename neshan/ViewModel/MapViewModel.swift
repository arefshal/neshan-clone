//
//  MapViewModel.swift
//  neshan
//
//  Created by Aref on 9/5/24.
//

import Foundation
import MapKit
import CoreLocation

class MapViewModel {
    
    var searchResults: [SearchResult] = [] {
        didSet {
            onUpdate?()
        }
    }
    
    var onUpdate: (() -> Void)?
    
    private let neshanService = NeshanAPIService()
    private let routingService = RoutingService()
    
    func search(query: String, lat: Double, lng: Double) {
        neshanService.searchPlaces(query: query, lat: lat, lng: lng) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let results):
                    self?.searchResults = results
                case .failure(let error):
                    print("Search failed: \(error.localizedDescription)")
                    self?.searchResults = []
                }
            }
        }
    }
    
    func getRoute(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, completion: @escaping (MKPolyline?) -> Void) {
        routingService.getRoute(from: origin, to: destination) { polyline in
            DispatchQueue.main.async {
                completion(polyline)
            }
        }
    }
    
    func getAnnotations() -> [MKAnnotation] {
        return searchResults.map { result in
            let annotation = MKPointAnnotation()
            annotation.title = result.title
            annotation.subtitle = result.address
            annotation.coordinate = CLLocationCoordinate2D(latitude: result.location.y, longitude: result.location.x)
            return annotation
        }
    }
}
