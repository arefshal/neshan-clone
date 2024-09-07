//
//  SearchResponse.swift
//  neshan
//
//  Created by Aref on 9/5/24.
//


import Foundation

struct SearchResponse: Codable {
    let items: [SearchResult]
}

struct SearchResult: Codable {
    let title: String
    let address: String
    let location: Location
}
