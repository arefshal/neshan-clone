//
//  MapViewController.swift
//  neshan
//

//

import UIKit
import MapKit
import CoreLocation

/// A view controller that displays a map with search functionality and routing capabilities.
class MapViewController: UIViewController {
    
    // MARK: - Properties
    
    let mapView = MKMapView()
    private let locationManager = CLLocationManager()
    private let showLocationButton = UIButton(type: .system)
    private let searchButton = UIButton(type: .system)
    private var currentRoute: MKPolyline?
    private let routingService = RoutingService()
    var userLocation: CLLocationCoordinate2D?
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupMapView()
        setupLocationManager()
        setupShowLocationButton()
        setupSearchButton()
        
        locationManager.requestWhenInUseAuthorization()
    }
    
    // MARK: - Setup Methods
    
    /// Sets up the main map view.
    private func setupMapView() {
        mapView.frame = self.view.bounds
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.showsUserLocation = true
        mapView.delegate = self
        self.view.addSubview(mapView)
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
    }
    
    private func setupShowLocationButton() {
        showLocationButton.setImage(UIImage(systemName: "location"), for: .normal)
        showLocationButton.backgroundColor = .white
        showLocationButton.layer.cornerRadius = 20
        showLocationButton.layer.shadowColor = UIColor.black.cgColor
        showLocationButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        showLocationButton.layer.shadowRadius = 2
        showLocationButton.layer.shadowOpacity = 0.25
        showLocationButton.addTarget(self, action: #selector(showCurrentLocation), for: .touchUpInside)
        
        view.addSubview(showLocationButton)
        showLocationButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            showLocationButton.widthAnchor.constraint(equalToConstant: 40),
            showLocationButton.heightAnchor.constraint(equalToConstant: 40),
            showLocationButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            showLocationButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupSearchButton() {
        searchButton.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        searchButton.backgroundColor = .white
        searchButton.layer.cornerRadius = 20
        searchButton.layer.shadowColor = UIColor.black.cgColor
        searchButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        searchButton.layer.shadowRadius = 2
        searchButton.layer.shadowOpacity = 0.25
        searchButton.addTarget(self, action: #selector(showSearchView), for: .touchUpInside)
        
        view.addSubview(searchButton)
        searchButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            searchButton.widthAnchor.constraint(equalToConstant: 40),
            searchButton.heightAnchor.constraint(equalToConstant: 40),
            searchButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            searchButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }
    
    // MARK: - Action Methods
    
    @objc private func showCurrentLocation() {
        if let userLocation = locationManager.location?.coordinate {
            let region = MKCoordinateRegion(center: userLocation, latitudinalMeters: 1000, longitudinalMeters: 1000)
            mapView.setRegion(region, animated: true)
            
            // Remove existing route if any
            if let currentRoute = currentRoute {
                mapView.removeOverlay(currentRoute)
                self.currentRoute = nil
            }
        }
    }
    
    @objc private func showSearchView() {
        let searchVC = SearchViewController()
        searchVC.mapViewController = self
        present(searchVC, animated: true, completion: nil)
    }
    
    // MARK: - Public Methods
    
    func pinLocation(title: String, coordinate: CLLocationCoordinate2D) {
        mapView.removeAnnotations(mapView.annotations)
        
        if let currentRoute = currentRoute {
            mapView.removeOverlay(currentRoute)
            self.currentRoute = nil
        }
        
        let annotation = MKPointAnnotation()
        annotation.title = title
        annotation.coordinate = coordinate
        
        mapView.addAnnotation(annotation)
        
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
        mapView.setRegion(region, animated: true)
    }
    
    func clearRoute() {
        if let currentRoute = currentRoute {
            mapView.removeOverlay(currentRoute)
            self.currentRoute = nil
        }
    }
    
    func showSearchResults(_ results: [SearchResult]) {
        
        mapView.removeAnnotations(mapView.annotations)
        clearRoute()
        
        // اضافه کردن انوتیشن‌های جدید به نقشه
        for result in results {
            let annotation = MKPointAnnotation()
            annotation.title = result.title
            annotation.coordinate = CLLocationCoordinate2D(latitude: result.location.y, longitude: result.location.x)
            mapView.addAnnotation(annotation)
        }
        
        // تنظیم نقشه به موقعیت اولین نتیجه
        if let firstResult = results.first {
            let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: firstResult.location.y, longitude: firstResult.location.x), latitudinalMeters: 5000, longitudinalMeters: 5000)
            mapView.setRegion(region, animated: true)
        }
    }
}
    
    // MARK: - Private Methods
    
    
    
    // MARK: - CLLocationManagerDelegate
    
    extension MapViewController: CLLocationManagerDelegate {
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            guard let location = locations.first else { return }
            userLocation = location.coordinate
            
            let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
            mapView.setRegion(region, animated: true)
            
            locationManager.stopUpdatingLocation()
        }
        
        func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
            print("Failed to get user location: \(error)")
        }
    }
    
    // MARK: - MKMapViewDelegate
    
    extension MapViewController: MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let annotation = view.annotation else { return }
            
            showRoute(to: annotation.coordinate)
     
            let pinLocation = PinLocation(
                title: (annotation.title ?? "Unknown Location") ?? "Unknown Location",
                latitude: annotation.coordinate.latitude,
                longitude: annotation.coordinate.longitude
            )
            
            
            saveLocationFromPin(pinLocation)
        }
        
        
        private func saveLocationFromPin(_ location: PinLocation) {
            let savedLocation = SavedLocation(context: CoreDataManager.shared.context)
            savedLocation.title = location.title
            savedLocation.latitude = location.latitude
            savedLocation.longitude = location.longitude
            CoreDataManager.shared.saveContext()
            
            print("Location saved: \(location.title)")
        }
        
        
        func showRoute(to destinationCoordinate: CLLocationCoordinate2D) {
            guard let userLocation = locationManager.location?.coordinate else { return }
            
            routingService.getRoute(from: userLocation, to: destinationCoordinate) { [weak self] polyline in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if let currentRoute = self.currentRoute {
                        self.mapView.removeOverlay(currentRoute)
                    }
                    
                    if let polyline = polyline {
                        self.currentRoute = polyline
                        self.mapView.addOverlay(polyline)
                        
                        
                        self.mapView.setVisibleMapRect(polyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50), animated: true)
                    }
                }
            }
        }
        
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor.blue
                renderer.lineWidth = 4.0
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !(annotation is MKUserLocation) else { return nil }
            
            let identifier = "CustomPin"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }
            
            return annotationView
        }
    }

