//
//  NeshanAPIService.swift
//  neshan
//
//  Created by Aref on 9/5/24.
//

import Foundation

class NeshanAPIService {
    // API credentials and base URL
    private let apiKey = "service.4ce361741bbd4a2391b15c1004763139"
    private let baseUrl = "https://api.neshan.org/v1/search"
    
    // Search for places using Neshan API
    func searchPlaces(query: String, lat: Double, lng: Double, completion: @escaping (Result<[SearchResult], Error>) -> Void) {
        // Construct URL components
        guard var urlComponents = URLComponents(string: baseUrl) else {
            completion(.failure(NSError(domain: "NeshanAPIService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid base URL"])))
            return
        }
        
        // Add query parameters
        urlComponents.queryItems = [
            URLQueryItem(name: "term", value: query),
            URLQueryItem(name: "lat", value: String(lat)),
            URLQueryItem(name: "lng", value: String(lng))
        ]
        
        // Create URL from components
        guard let url = urlComponents.url else {
            completion(.failure(NSError(domain: "NeshanAPIService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to construct URL"])))
            return
        }
        
        // Prepare the request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(apiKey, forHTTPHeaderField: "Api-Key")
        
        // Perform the network request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "NeshanAPIService", code: 2, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            // Log the raw data
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw JSON response: \(jsonString)")
            }
            
            // Parse the JSON response
            do {
                let decoder = JSONDecoder()
                let searchResponse = try decoder.decode(SearchResponse.self, from: data)
                completion(.success(searchResponse.items))
            } catch {
                print("Error decoding JSON: \(error)")
                completion(.failure(error))
            }
        }

        task.resume()
    }
}
