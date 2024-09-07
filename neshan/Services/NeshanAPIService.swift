//
//  NeshanAPIService.swift
//  neshan
//
//  Created by Aref on 9/5/24.
//


import Foundation

class NeshanAPIService {
    private let apiKey = "service.4ce361741bbd4a2391b15c1004763139"
    private let baseUrl = "https://api.neshan.org/v1/search"
    
    func searchPlaces(query: String, lat: Double, lng: Double, completion: @escaping (Result<[SearchResult], Error>) -> Void) {
        guard var urlComponents = URLComponents(string: baseUrl) else {
            completion(.failure(NSError(domain: "NeshanAPIService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid base URL"])))
            return
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "term", value: query),
            URLQueryItem(name: "lat", value: String(lat)),
            URLQueryItem(name: "lng", value: String(lng))
        ]
        
        guard let url = urlComponents.url else {
            completion(.failure(NSError(domain: "NeshanAPIService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to construct URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(apiKey, forHTTPHeaderField: "Api-Key")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "NeshanAPIService", code: 2, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let searchResponse = try decoder.decode(SearchResponse.self, from: data)
                completion(.success(searchResponse.items))
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
}
