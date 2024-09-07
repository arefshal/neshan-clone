//
//  SearchViewModel.swift
//  neshan
//
//  Created by Aref on 9/5/24.
//

import Foundation
import CoreLocation

class SearchViewModel {

    var searchResults: [SearchResult] = [] {
        didSet {
            onUpdate?()
        }
    }
    
    var onUpdate: (() -> Void)?
    
    private let neshanService = NeshanAPIService()

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

    func getAnnotations() -> [CLLocationCoordinate2D] {
        return searchResults.map { result in
            return CLLocationCoordinate2D(latitude: result.location.y, longitude: result.location.x)
        }
    }

    func getTitles() -> [String] {
        return searchResults.map { $0.title }
    }

    func numberOfResults() -> Int {
        return searchResults.count
    }

    func getResult(at index: Int) -> SearchResult? {
        guard index >= 0 && index < searchResults.count else { return nil }
        return searchResults[index]
    }
}
