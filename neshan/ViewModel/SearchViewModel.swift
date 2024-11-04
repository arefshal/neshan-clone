import Foundation
import MapKit

class SearchViewModel {

    // MARK: - Properties
    
    var searchResults: [SearchResult] = [] {
        didSet {
            onUpdate?()
        }
    }
    
    var savedLocations: [SavedLocation] = [] {
        didSet {
            onUpdate?()
        }
    }
    
    var onUpdate: (() -> Void)?
    var onError: ((String) -> Void)?
    var onSelectLocation: ((SearchResult) -> Void)?
    var onSelectSavedLocation: ((SavedLocation) -> Void)?
    
    private let neshanService = NeshanAPIService()
    private let routingService = RoutingService()
    private let coreDataManager = CoreDataManager.shared
    var isLoading: Bool = false {
        didSet {
            onUpdate?()
        }
    }
    
    var searchQuery: String = "" {
        didSet {
            if searchQuery.isEmpty {
                clearResults()
                fetchSavedLocations()
            } else {
                if let location = userLocation {
                    search(query: searchQuery, lat: location.latitude, lng: location.longitude)
                }
            }
        }
    }
    
    var isSearching: Bool {
        return !searchQuery.isEmpty
    }
    
    var userLocation: CLLocationCoordinate2D?

    // MARK: - Data Management Methods

    func fetchSavedLocations() {
        savedLocations = coreDataManager.fetchSavedLocations()
    }
    
    func saveLocation(_ location: SearchResult) {
        let isDuplicate = savedLocations.contains { savedLocation in
            return savedLocation.title == location.title &&
                   savedLocation.latitude == location.location.y &&
                   savedLocation.longitude == location.location.x
        }
        
        if !isDuplicate {
            coreDataManager.saveLocation(location)
            fetchSavedLocations()
        } else {
            print("Location already saved.")
        }
    }
    
    func deleteLocation(at index: Int) {
        let locationToDelete = savedLocations[index]
        coreDataManager.deleteLocation(locationToDelete)
        fetchSavedLocations()
    }
    
    // MARK: - Search and Networking Methods
    
    func search(query: String, lat: Double, lng: Double) {
        guard NetworkManager.shared.isConnectedToNetwork() else {
            onError?("No internet connection. Please try again.")
            return
        }
        
        isLoading = true
        neshanService.searchPlaces(query: query, lat: lat, lng: lng) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let results):
                    self?.searchResults = results
                case .failure(let error):
                    print("Search failed: \(error.localizedDescription)")
                    self?.onError?("Search failed: \(error.localizedDescription)")
                    self?.searchResults = []
                }
            }
        }
    }

    // MARK: - Helper Methods for Data Access

    func numberOfItems() -> Int {
        return isSearching ? searchResults.count : savedLocations.count
    }
    
    func item(at index: Int) -> String {
        if isSearching {
            return searchResults[index].title
        } else {
            return savedLocations[index].title ?? ""
        }
    }

    func selectItem(at index: Int) {
        if isSearching {
            let result = searchResults[index]
            saveLocation(result)
            onSelectLocation?(result)
        } else {
            let savedLocation = savedLocations[index]
            onSelectSavedLocation?(savedLocation)
        }
    }

    // MARK: - Utility Methods
    
    func getAnnotations() -> [MKAnnotation] {
        return searchResults.map { result in
            let annotation = MKPointAnnotation()
            annotation.title = result.title
            annotation.subtitle = result.address
            annotation.coordinate = CLLocationCoordinate2D(latitude: result.location.y, longitude: result.location.x)
            return annotation
        }
    }

    func getResult(at index: Int) -> SearchResult? {
        guard index >= 0 && index < searchResults.count else { return nil }
        return searchResults[index]
    }
    
    func clearResults() {
        searchResults = []
        onUpdate?()
    }
}
