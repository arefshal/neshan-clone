//
//  RouteResponse.swift
//  neshan
//
//  Created by Aref on 9/5/24.
//

import Foundation

struct RouteResponse: Codable {
    let routes: [Route]
}

struct Route: Codable {
    let overview_polyline: OverviewPolyline
}

struct OverviewPolyline: Codable {
    let points: String
}
