//
//  ICMPPinger.swift
//  NetworkMonitorAgent
//
//  Created by Maurice Roach on 13/12/2025.
//

import Foundation
import Network

class ICMPPinger {
    struct PingResult {
        let rtt: Double? // Round-trip time in ms
        let packetLoss: Double? // Packet loss in percentage
    }
    
    /// Executes the ping command and parses the output.
    func ping(host: String, count: Int = 4, timeout: Int = 1) -> PingResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/sbin/ping")
        process.arguments = ["-c", "\(count)", "-t", "\(timeout)", host]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            
            if let output = String(data: data, encoding: .utf8) {
                return parsePingOutput(output)
            }
        } catch {
            print("Ping failed to run: \(error.localizedDescription)")
        }
        
        return PingResult(rtt: nil, packetLoss: nil)
    }
    
    /// Parses the string output from the ping command.
    private func parsePingOutput(_ output: String) -> PingResult {
        var rtt: Double?
        var packetLoss: Double?
        
        // Example output for packet loss: "4 packets transmitted, 4 packets received, 0.0% packet loss"
        if let lossRegex = try? NSRegularExpression(pattern: "(\\d+\\.?\\d*)% packet loss"),
           let match = lossRegex.firstMatch(in: output, range: NSRange(output.startIndex..., in: output)),
           let range = Range(match.range(at: 1), in: output) {
            packetLoss = Double(output[range])
        }
        
        // Example output for RTT: "round-trip min/avg/max/stddev = 10.327/11.569/13.435/1.235 ms"
        if let rttRegex = try? NSRegularExpression(pattern: "round-trip min/avg/max/stddev = (\\d+\\.?\\d*)/(\\d+\\.?\\d*)/(\\d+\\.?\\d*)/(\\d+\\.?\\d*) ms"),
           let match = rttRegex.firstMatch(in: output, range: NSRange(output.startIndex..., in: output)),
           let range = Range(match.range(at: 2), in: output) { // avg rtt
            rtt = Double(output[range])
        }
        
        return PingResult(rtt: rtt, packetLoss: packetLoss)
    }
}
