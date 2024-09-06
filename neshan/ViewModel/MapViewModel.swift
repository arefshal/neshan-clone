//
//  MapViewModel.swift
//  neshan
//
//  Created by Aref on 9/5/24.
//

import Foundation
import MapKit
import CoreLocation

/// ViewModel responsible for managing map-related data and operations.
class MapViewModel {
    
    // MARK: - Properties
    
    /// Array of search results. Updates trigger the `onUpdate` closure.
    var searchResults: [SearchResult] = [] {
        didSet {
            onUpdate?()
        }
    }
    
    /// Closure called when search results are updated.
    var onUpdate: (() -> Void)?
    
    /// Service for handling Neshan API requests.
    private let neshanService = NeshanAPIService()
    
    /// Service for handling routing operations.
    private let routingService = RoutingService()
    
    // MARK: - Public Methods
    
    /// Performs a search for places near a specified location.
    ///
    /// - Parameters:
    ///   - query: The search query string.
    ///   - lat: The latitude of the search center.
    ///   - lng: The longitude of the search center.
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
    
    /// Retrieves a route between two points.
    ///
    /// - Parameters:
    ///   - origin: The starting point of the route.
    ///   - destination: The end point of the route.
    ///   - completion: A closure called with the resulting polyline, or nil if routing failed.
    func getRoute(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, completion: @escaping (MKPolyline?) -> Void) {
        routingService.getRoute(from: origin, to: destination) { polyline in
            DispatchQueue.main.async {
                completion(polyline)
            }
        }
    }
    
    /// Converts search results to map annotations.
    ///
    /// - Returns: An array of `MKAnnotation` objects representing the search results.
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
