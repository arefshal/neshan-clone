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

    override func viewDidLoad() {
        super.viewDidLoad()

       
        setupMapView()
        setupSearchBar()
        setupLocationManager()
        setupBindings()

        
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

   
    func showRoute(to destinationCoordinate: CLLocationCoordinate2D) {
        guard let userLocation = locationManager.location?.coordinate else { return }

       
        viewModel.getRoute(from: userLocation, to: destinationCoordinate) { [weak self] polyline in
            if let polyline = polyline {
                DispatchQueue.main.async {
                    self?.mapView.addOverlay(polyline)
                    self?.mapView.setVisibleMapRect(polyline.boundingMapRect, animated: true)
                }
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension MapViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        
        
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
