//
//  ViewController.swift
//  neshan
//
//  Created by Aref on 9/5/24.
//

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController {
    
    private let mapView = MKMapView()
    private let searchBar = UISearchBar()
    private let viewModel = MapViewModel()
    private let locationManager = CLLocationManager()
    private let routingService = RoutingService()
    private var currentRoute: MKPolyline?
    private let showLocationButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupMapView()
        setupSearchBar()
        setupLocationManager()
        setupBindings()
        setupShowLocationButton()
        
        locationManager.requestWhenInUseAuthorization()
    }
    
    private func setupMapView() {
        mapView.frame = self.view.bounds
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.showsUserLocation = true
        mapView.delegate = self
        self.view.addSubview(mapView)
    }
    
    private func setupSearchBar() {
        searchBar.delegate = self
        searchBar.placeholder = "Search for places..."
        searchBar.sizeToFit()
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(searchBar)
        
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        ])
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
    }
    
    private func setupBindings() {
        viewModel.onUpdate = { [weak self] in
            self?.updateMapAnnotations()
        }
    }
    
    private func updateMapAnnotations() {
        mapView.removeAnnotations(mapView.annotations)
        let annotations = viewModel.getAnnotations()
        mapView.addAnnotations(annotations)
    }
    
    private func showRoute(to destinationCoordinate: CLLocationCoordinate2D) {
        guard let userLocation = locationManager.location?.coordinate else { return }
        
        viewModel.getRoute(from: userLocation, to: destinationCoordinate) { [weak self] polyline in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                // Remove the previous route if it exists
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
}

// MARK: - CLLocationManagerDelegate
extension MapViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        
        // Center the map on the user's location when it's first obtained
        let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
        mapView.setRegion(region, animated: true)
        
        viewModel.search(query: "Cafe", lat: location.coordinate.latitude, lng: location.coordinate.longitude)
        
        locationManager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get user location: \(error)")
    }
}

// MARK: - MKMapViewDelegate
extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(overlay: polyline)
            renderer.strokeColor = UIColor.blue
            renderer.lineWidth = 4.0
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let annotation = view.annotation {
            showRoute(to: annotation.coordinate)
        }
    }
}

// MARK: - UISearchBarDelegate
extension MapViewController: UISearchBarDelegate {
    
   
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let query = searchBar.text, !query.isEmpty else { return }

        
        if let userLocation = locationManager.location {
            let lat = userLocation.coordinate.latitude
            let lng = userLocation.coordinate.longitude
            viewModel.search(query: query, lat: lat, lng: lng)
        }
        
        searchBar.resignFirstResponder()
    }
}
