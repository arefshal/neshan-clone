//
//  SearchViewController.swift
//  neshan
//

import UIKit
import MapKit

class SearchViewController: UIViewController {

    // MARK: - Properties
    
    private let tableView = UITableView()
    private let searchBar = UISearchBar()
    private let searchViewModel = SearchViewModel()
    private let mapButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private var savedLocations: [SavedLocation] = []
    weak var mapViewController: MapViewController?
    var userLocation: CLLocationCoordinate2D?

    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupBindings()
        loadSavedLocations()
        userLocation = mapViewController?.userLocation
    }

    // MARK: - Setup Methods
    
    private func setupUI() {
        view.backgroundColor = .white
        setupSearchBar()
        setupTableView()
        setupMapButton()
        setupActivityIndicator()
    }
    
    private func setupSearchBar() {
        searchBar.placeholder = "Search for places..."
        searchBar.delegate = self
        view.addSubview(searchBar)
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupMapButton() {
        mapButton.setTitle("Show Map", for: .normal)
        mapButton.addTarget(self, action: #selector(showMap), for: .touchUpInside)
        view.addSubview(mapButton)
        mapButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mapButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            mapButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }

    private func setupActivityIndicator() {
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func setupBindings() {
        searchViewModel.onUpdate = { [weak self] in
            DispatchQueue.main.async {
                if self?.searchViewModel.isLoading == true {
                    self?.activityIndicator.startAnimating()
                } else {
                    self?.activityIndicator.stopAnimating()
                    self?.tableView.reloadData()
                }
            }
        }

        searchViewModel.onError = { [weak self] errorMessage in
            DispatchQueue.main.async {
                self?.showAlertForError(message: errorMessage)
            }
        }
    }

    // MARK: - Helper Methods
    
    private func loadSavedLocations() {
        savedLocations = CoreDataManager.shared.fetchSavedLocations()
        tableView.reloadData()
    }
    
    private func saveLocation(_ location: SearchResult) {
        let isDuplicate = savedLocations.contains { savedLocation in
            return savedLocation.title == location.title &&
                   savedLocation.latitude == location.location.y &&
                   savedLocation.longitude == location.location.x
        }
        
        if !isDuplicate {
            CoreDataManager.shared.saveLocation(location)
            loadSavedLocations()
        } else {
            print("Location already saved.")
        }
    }
    
    private func deleteLocation(at index: Int) {
        let locationToDelete = savedLocations[index]
        CoreDataManager.shared.deleteLocation(locationToDelete)
        loadSavedLocations()
    }
    
    private func pinLocationOnMap(_ location: SearchResult) {
        guard let mapVC = mapViewController else { return }
        
        let coordinate = CLLocationCoordinate2D(latitude: location.location.y, longitude: location.location.x)
        mapVC.pinLocation(title: location.title, coordinate: coordinate)
        
        dismiss(animated: true, completion: nil)
    }

    private func showAlertForError(message: String) {
        let alert = UIAlertController(title: "No Internet Connection", message: message, preferredStyle: .alert)
        
        
        alert.addAction(UIAlertAction(title: "Retry", style: .default, handler: { [weak self] _ in
            self?.searchBarSearchButtonClicked(self?.searchBar ?? UISearchBar())
        }))
        
        
        alert.addAction(UIAlertAction(title: "Go to Settings", style: .default, handler: { _ in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
            }
        }))
        
        // Cancel action
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }

    
    // MARK: - Action Methods
    
    @objc private func showMap() {
        guard let mapVC = mapViewController else { return }
        mapVC.showSearchResults(searchViewModel.searchResults)
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - UISearchBarDelegate

extension SearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            searchViewModel.clearResults()
            loadSavedLocations()
        } else if let location = userLocation {
            searchViewModel.search(query: searchText, lat: location.latitude, lng: location.longitude)
        }
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard NetworkManager.shared.isConnectedToNetwork() else {
            showAlertForError(message: "The network is disconnected. Please try again.")
            return
        }
        
        guard let mapVC = mapViewController else { return }
        
        mapVC.mapView.removeAnnotations(mapVC.mapView.annotations)
        mapVC.showSearchResults(searchViewModel.searchResults)
        
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - UITableViewDataSource

extension SearchViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchBar.text?.isEmpty == true ? savedLocations.count : searchViewModel.numberOfResults()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        if searchBar.text?.isEmpty == true {
            cell.textLabel?.text = savedLocations[indexPath.row].title
        } else {
            cell.textLabel?.text = searchViewModel.searchResults[indexPath.row].title
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return searchBar.text?.isEmpty == true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteLocation(at: indexPath.row)
        }
    }
}

// MARK: - UITableViewDelegate

extension SearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if searchBar.text?.isEmpty == true {
            let savedLocation = savedLocations[indexPath.row]
            let coordinate = CLLocationCoordinate2D(latitude: savedLocation.latitude, longitude: savedLocation.longitude)
            mapViewController?.pinLocation(title: savedLocation.title ?? "", coordinate: coordinate)
            dismiss(animated: true, completion: nil)
        } else {
            if let result = searchViewModel.getResult(at: indexPath.row) {
                saveLocation(result)
                pinLocationOnMap(result)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard searchBar.text?.isEmpty == true else { return nil }
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (_, _, completionHandler) in
            self?.deleteLocation(at: indexPath.row)
            completionHandler(true)
        }
        deleteAction.backgroundColor = .red
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        return configuration
    }
}
