//
//  SearchViewController.swift
//  neshan
//
//  Created by Aref on 9/5/24.
//

import UIKit

class SearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private let tableView = UITableView()
    private let searchViewModel = SearchViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupTableView()
        setupBindings()
        
        searchViewModel.search(query: "Cafe", lat: 35.6892, lng: 51.3890)
    }
    
  
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.frame = view.bounds
        view.addSubview(tableView)
    }
    
    
    private func setupBindings() {
        searchViewModel.onUpdate = { [weak self] in
            self?.tableView.reloadData()
        }
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchViewModel.numberOfResults()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = searchViewModel.getTitles()[indexPath.row] 
        return cell
    }
    
    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let result = searchViewModel.getResult(at: indexPath.row) {
            print("Selected place: \(result.title), \(result.address)")
        }
    }
}
