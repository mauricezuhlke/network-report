//
//  NetworkMonitorAgentTests.swift
//  NetworkMonitorAgentTests
//
//  Created by Maurice Roach on 13/12/2025.
//

import XCTest
@testable import NetworkMonitorAgent

class ICMPPingerTests: XCTestCase {

    func testPing_WithValidHost_ReturnsResult() {
        // Arrange
        let pinger = ICMPPinger()
        let host = "1.1.1.1" // A reliable host

        // Act
        let result = pinger.ping(host: host)

        // Assert
        XCTAssertNotNil(result.rtt, "RTT should not be nil for a valid host.")
        XCTAssertNotNil(result.packetLoss, "Packet loss should not be nil for a valid host.")
        if let rtt = result.rtt {
            XCTAssertGreaterThan(rtt, 0, "RTT should be greater than 0.")
        }
        if let packetLoss = result.packetLoss {
            XCTAssertGreaterThanOrEqual(packetLoss, 0, "Packet loss should be 0 or greater.")
            XCTAssertLessThanOrEqual(packetLoss, 100, "Packet loss should be 100 or less.")
        }
    }

    func testPing_WithInvalidHost_ReturnsNil() {
        // Arrange
        let pinger = ICMPPinger()
        let host = "nonexistent.host.this.should.fail"

        // Act
        let result = pinger.ping(host: host)

        // Assert
        XCTAssertNil(result.rtt, "RTT should be nil for an invalid host.")
    }
}