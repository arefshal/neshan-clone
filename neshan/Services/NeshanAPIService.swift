//
//  NeshanAPIService.swift
//  neshan
//
//  Created by Aref on 9/5/24.
//


import Foundation

class NeshanAPIService {
    let apiKey = "YOUR_API_KEY" // کلید API شما
    
    // جستجوی مکان‌ها با استفاده از Neshan API
    func searchPlaces(query: String, lat: Double, lng: Double, completion: @escaping ([SearchResult]) -> Void) {
        let baseUrl = "https://api.neshan.org/v1/search"
        let urlString = "\(baseUrl)?term=\(query)&lat=\(lat)&lng=\(lng)"
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            completion([])
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(apiKey, forHTTPHeaderField: "Api-Key")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error fetching places: \(String(describing: error))")
                completion([])
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let searchResponse = try decoder.decode(SearchResponse.self, from: data)
                completion(searchResponse.items)
            } catch {
                print("Error decoding search results: \(error)")
                completion([])
            }
        }
        
        task.resume()
    }
}
