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
    weak var mapViewController: MapViewController?
    var userLocation: CLLocationCoordinate2D?

    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupBindings()
        searchViewModel.fetchSavedLocations()
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
                self?.activityIndicator.isHidden = !(self?.searchViewModel.isLoading ?? false)
                self?.tableView.reloadData()
            }
        }

        searchViewModel.onError = { [weak self] errorMessage in
            DispatchQueue.main.async {
                self?.showAlertForError(message: errorMessage)
            }
        }

        searchViewModel.onSelectLocation = { [weak self] location in
            self?.pinLocationOnMap(location)
        }
        
        searchViewModel.onSelectSavedLocation = { [weak self] savedLocation in
            let coordinate = CLLocationCoordinate2D(latitude: savedLocation.latitude, longitude: savedLocation.longitude)
            self?.mapViewController?.pinLocation(title: savedLocation.title ?? "", coordinate: coordinate)
            self?.dismiss(animated: true, completion: nil)
        }
    }

    // MARK: - Helper Methods

    private func showAlertForError(message: String) {
        let alert = UIAlertController(title: "No Internet Connection", message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Retry", style: .default, handler: { [weak self] _ in
            self?.searchBarSearchButtonClicked(self?.searchBar ?? UISearchBar())
        }))
        
        alert.addAction(UIAlertAction(title: "Go to Settings", style: .default, handler: { _ in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }

    private func pinLocationOnMap(_ location: SearchResult) {
        guard let mapVC = mapViewController else { return }
        
        let coordinate = CLLocationCoordinate2D(latitude: location.location.y, longitude: location.location.x)
        mapVC.pinLocation(title: location.title, coordinate: coordinate)
        
        dismiss(animated: true, completion: nil)
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
        searchViewModel.searchQuery = searchText
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
        return searchViewModel.numberOfItems()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = searchViewModel.item(at: indexPath.row)
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return !searchViewModel.isSearching
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            searchViewModel.deleteLocation(at: indexPath.row)
        }
    }
}

// MARK: - UITableViewDelegate

extension SearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        searchViewModel.selectItem(at: indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard !searchViewModel.isSearching else { return nil }
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (_, _, completionHandler) in
            self?.searchViewModel.deleteLocation(at: indexPath.row)
            completionHandler(true)
        }
        
        deleteAction.backgroundColor = .red
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}
