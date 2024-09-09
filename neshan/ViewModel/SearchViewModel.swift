import MapKit
import CoreLocation

class SearchViewModel {

    var searchResults: [SearchResult] = [] {
        didSet {
            onUpdate?()
        }
    }

    var onUpdate: (() -> Void)?
    var onError: ((String) -> Void)?
    var isLoading: Bool = false {
        didSet {
            onUpdate?()
        }
    }

    private let neshanService = NeshanAPIService()
    private let routingService = RoutingService()

    // Fetch nearby places (e.g., cafes) based on query and current location
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

    // Provide annotations to be shown on the map for all search results
    func getAnnotations() -> [MKAnnotation] {
        return searchResults.map { result in
            let annotation = MKPointAnnotation()
            annotation.title = result.title
            annotation.subtitle = result.address
            annotation.coordinate = CLLocationCoordinate2D(latitude: result.location.y, longitude: result.location.x)
            return annotation
        }
    }

    // Return the number of search results
    func numberOfResults() -> Int {
        return searchResults.count
    }

    // Get a specific search result at a given index
    func getResult(at index: Int) -> SearchResult? {
        guard index >= 0 && index < searchResults.count else { return nil }
        return searchResults[index]
    }

    // Clear search results
    func clearResults() {
        searchResults = []
        onUpdate?()
    }
}
