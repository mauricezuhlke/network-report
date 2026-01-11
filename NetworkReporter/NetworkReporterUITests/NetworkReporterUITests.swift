//
//  NetworkReporterUITests.swift
//  NetworkReporterUITests
//
//  Created by Gemini on 03/01/2026.
//

import XCTest

final class NetworkReporterUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Check if the main window and key static text exist
        XCTAssert(app.staticTexts["Real-Time Network Status"].exists)
    }

    func testRealTimeViewElements() throws {
        let app = XCUIApplication()
        app.launch()

        // Give the app a moment to connect to the service and get data
        let statusLabel = app.staticTexts["Status:"]
        XCTAssert(statusLabel.waitForExistence(timeout: 10))

        // Check for the existence of the elements in the RealTimeNetworkView
        XCTAssert(app.staticTexts["Status:"].exists)
        XCTAssert(app.staticTexts["Last updated:"].exists)
    }

    func testNavigateToHistoricalViewAndVerifyCharts() throws {
        let app = XCUIApplication()
        app.launch()

        // Tap the navigation link to the historical view
        app.buttons["View History"].tap()

        // Verify that the historical view is displayed
        XCTAssert(app.staticTexts["Historical Network Performance"].waitForExistence(timeout: 5))

        // Verify the titles of the charts exist
        XCTAssert(app.staticTexts["Latency Over Time"].exists)
        XCTAssert(app.staticTexts["Packet Loss Over Time"].exists)
        XCTAssert(app.staticTexts["Connectivity Status Over Time"].exists)
        XCTAssert(app.staticTexts["Upload/Download Speed Over Time"].exists)

        // Verify the time range picker exists
        XCTAssert(app.pickers["Time Range"].exists)

        // Verify the degradation annotation text exists, which confirms the RuleMarks are present
        XCTAssert(app.staticTexts["High Latency (200ms)"].exists)
        XCTAssert(app.staticTexts["High Packet Loss (5%)"].exists)
    }
}
