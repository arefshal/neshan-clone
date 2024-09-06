//
//  SearchResult.swift
//  neshan
//
//  Created by Aref on 9/5/24.
//

import Foundation

struct SearchResult: Codable {
    let title: String
    let address: String
    let neighbourhood: String?
    let region: String
    let type: String
    let category: String
    let location: Location
}
struct SearchResponse: Codable {
    let count: Int
    let items: [SearchResult]
}
