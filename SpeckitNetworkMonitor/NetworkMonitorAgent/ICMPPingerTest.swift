//
//  ICMPPingerTest.swift
//  NetworkMonitorAgent
//
//  Created by Maurice Roach on 13/12/2025.
//

import Foundation

// This is a temporary file to test the ICMPPinger.
// It will be deleted after the test.

// This file contains test code for ICMPPinger.
// The ICMPPinger class is defined in the main ICMPPinger.swift file.

func testPinger() {
    let pinger = ICMPPinger()
    
    print("Pinging 1.1.1.1...")
    let result1 = pinger.ping(host: "1.1.1.1")
    print("RTT: \(result1.rtt ?? -1), Packet Loss: \(result1.packetLoss ?? -1)%")

    print("\nPinging a non-existent host...")
    let result2 = pinger.ping(host: "nonexistent.host.xyz")
    print("RTT: \(result2.rtt ?? -1), Packet Loss: \(result2.packetLoss ?? -1)%")
}

//testPinger()
