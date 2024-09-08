//
//  SavedLocationCodable.swift
//  neshan
//
//  Created by Aref on 9/8/24.
//


import Foundation

struct SavedLocationCodable: Codable {
    let title: String
    let latitude: Double
    let longitude: Double
    
    init(from savedLocation: SavedLocation) {
        self.title = savedLocation.title ?? ""
        self.latitude = savedLocation.latitude
        self.longitude = savedLocation.longitude
    }
}
