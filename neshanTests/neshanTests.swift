//
//  neshanTests.swift
//  neshanTests
//
//  Created by Aref on 9/5/24.
//

import XCTest
import CoreLocation
@testable import neshan

final class neshanTests: XCTestCase {
    
    var routingService: RoutingService!

    override func setUpWithError() throws {
        super.setUp()
        routingService = RoutingService()
    }

    override func tearDownWithError() throws {
        routingService = nil
        super.tearDown()
    }

    func testExample() throws {
        
    }

    func testPerformanceExample() throws {
        
        self.measure {
            
        }
    }

    func testGetRoute() throws {
        let expectation = self.expectation(description: "Get route")
        
        let origin = CLLocationCoordinate2D(latitude: 35.7219, longitude: 51.3347)
        let destination = CLLocationCoordinate2D(latitude: 35.7137, longitude: 51.4148)
        
        routingService.getRoute(from: origin, to: destination) { polyline in
            XCTAssertNotNil(polyline, "Polyline should not be nil")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
}
