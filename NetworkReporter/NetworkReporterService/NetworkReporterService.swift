//
//  NetworkReporterService.swift
//  NetworkReporterService
//
//  Created by Maurice Roach on 22/12/2025.
//

import Foundation
import Network // For network connectivity information
import NetworkReporterShared // FIX: For ConnectivityStatus and Protocols

enum NetworkReporterServiceError: Error, LocalizedError {
    case monitoringNotActive
    case failedToMeasurePerformance
    case invalidDateRange
    
    var errorDescription: String? {
        switch self {
        case .monitoringNotActive: return "Network monitoring is not active."
        case .failedToMeasurePerformance: return "Failed to measure network performance."
        case .invalidDateRange: return "Invalid date range provided for historical data."
        }
    }
}

/// This object implements the protocol which we have defined. It provides the actual behavior for the service. It is 'exported' by the service to make it available to the process hosting the service over an NSXPCConnection.

class NetworkReporterService: NSObject, NetworkReporterServiceProtocol {

    

    // Reference to the client's exported object, for reverse communication

    weak var client: NetworkReporterClientProtocol?



    private var isMonitoring = false

    private var monitoringTimer: DispatchSourceTimer?

    private var lastMeasuredPerformance: [String: Any]? // Stores last measured data

    private var currentMonitoringInterval: Double = 5.0 // Default monitoring interval in seconds

    

    // NWPathMonitor for network reachability

    private let pathMonitor = NWPathMonitor()

    private let monitorQueue = DispatchQueue(label: "NetworkMonitorQueue")

    private var isConnectedToInternet = false



    override init() {

        super.init()

        self.setupPathMonitor()

    }

    

    deinit {

        pathMonitor.cancel() // Ensure path monitor is cancelled

    }

    

    private func setupPathMonitor() {

        pathMonitor.pathUpdateHandler = { [weak self] path in

            self?.isConnectedToInternet = (path.status == .satisfied)

            NSLog("Network path status changed: \(path.status == .satisfied ? "Connected" : "Disconnected")")

            // Potentially inform client about connectivity change immediately

        }

        self.pathMonitor.start(queue: monitorQueue)

    }



    /// This implements the example protocol. Replace the body of this class with the implementation of this service's protocol.

    @objc func getTimestamp(with reply: @escaping (String?, Error?) -> Void) {

        let dateFormatter = ISO8601DateFormatter()

        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let timestampString = dateFormatter.string(from: Date())

        

        reply(timestampString, nil) // No error for successful timestamp generation

    }



    @objc func startMonitoring(with reply: @escaping (Error?) -> Void) {
        guard !isMonitoring else {
            reply(nil) // Already monitoring
            return
        }
        isMonitoring = true
        NSLog("NetworkReporterService: Monitoring enabled.")
        
        // If the client is already set, start the timer immediately.
        // Otherwise, the timer will be started when the client registers.
        if client != nil {
            startTimer()
        }
        
        reply(nil)
    }

    @objc func stopMonitoring(with reply: @escaping (Error?) -> Void) {
        guard isMonitoring else {
            reply(nil) // Not monitoring
            return
        }
        isMonitoring = false
        monitoringTimer?.cancel()
        monitoringTimer = nil
        NSLog("NetworkReporterService: Monitoring stopped.")
        reply(nil)
    }
    
    @objc func updateMonitoringInterval(to interval: Double, with reply: @escaping (Error?) -> Void) {
        NSLog("NetworkReporterService: Updating monitoring interval to \(interval)s.")
        currentMonitoringInterval = interval
        
        // If monitoring is active, restart the timer with the new interval.
        if isMonitoring {
            monitoringTimer?.cancel()
            startTimer()
        }
        
        reply(nil)
    }
    
    @objc func registerClient() {
        NSLog("NetworkReporterService: Client registered.")
        // If monitoring has already been enabled, start the timer now that we have a client.
        if isMonitoring {
            startTimer()
        }
    }
    
        private func startTimer() {
    
            monitoringTimer?.cancel()
    
            
    
            let timer = DispatchSource.makeTimerSource(queue: monitorQueue)
    
            timer.schedule(deadline: .now(), repeating: currentMonitoringInterval)
    
            timer.setEventHandler { [weak self] in
    
                guard let self = self else { return }
    
                
    
                Task {
    
                    let record = await self._measureNetworkPerformance()
    
                    self.lastMeasuredPerformance = record
    
                    
    
                    if let client = self.client {
    
                        client.handlePerformanceRecord(record)
    
                    } else {
    
                        NSLog("NetworkReporterService: Client proxy is nil. Cannot send performance record.")
    
                    }
    
                }
    
            }
    
            timer.resume()
    
            monitoringTimer = timer
    
        }
    
        
    
        @objc func getCurrentPerformance(with reply: @escaping ([String: Any]?, Error?) -> Void) {
    
            // Return the last measured performance if available, otherwise measure on demand
    
            if let last = lastMeasuredPerformance {
    
                reply(last, nil)
    
            } else {
    
                Task {
    
                    let currentMetrics = await self._measureNetworkPerformance()
    
                    self.lastMeasuredPerformance = currentMetrics
    
                    reply(currentMetrics, nil)
    
                }
    
            }
    
        }
    
    
    
        // MARK: - Real Network Performance Measurement
    
        
    
        private func _measureNetworkPerformance() async -> [String: Any] {
    
            var latency = 0.0
    
            var packetLoss = 0.0
    
            var connectivityStatus: Int16 = ConnectivityStatus.disconnected.rawValue
    
            
    
            if isConnectedToInternet {
    
                NSLog("Measuring network performance...")
    
                let (pingLatency, pingPacketLoss) = await _executePing()
    
                latency = pingLatency
    
                packetLoss = pingPacketLoss
    
                
    
                if latency > 0 {
    
                    connectivityStatus = (latency > 200 || packetLoss > 0.05) ? ConnectivityStatus.degraded.rawValue : ConnectivityStatus.connected.rawValue
    
                }
    
                
    
            } else {
    
                NSLog("Not connected to internet. Reporting disconnected state.")
    
                latency = 9999.0
    
                packetLoss = 1.0
    
                connectivityStatus = ConnectivityStatus.disconnected.rawValue
    
            }
    
            
    
            // Speed metrics are 0.0 as speedtest-cli was not found.
    
            let uploadSpeed = 0.0
    
            let downloadSpeed = 0.0
    
            if isConnectedToInternet {
    
                 NSLog("speedtest-cli not found. Skipping speed measurement. To enable, install speedtest-cli (e.g., 'brew install speedtest-cli').")
    
            }
    
    
    
            let timestamp = Date()
    
            let record: [String: Any] = [
    
                "id": UUID().uuidString,
    
                "timestamp": timestamp,
    
                "latency": latency,
    
                "packetLoss": packetLoss,
    
                "connectivityStatus": connectivityStatus,
    
                "uploadSpeed": uploadSpeed,
    
                "downloadSpeed": downloadSpeed
    
            ]
    
    
    
            NSLog("Performance record created: latency=\(latency)ms, packetLoss=\(packetLoss)%")
    
            return record
    
        }
    
    
    
        private func _executePing(host: String = "8.8.8.8", count: Int = 4) async -> (latency: Double, packetLoss: Double) {
    
            let command = "ping -c \(count) \(host)"
    
            do {
    
                let output = try await _runShellCommand(command)
    
                let latency = _parsePingLatency(from: output)
    
                let packetLoss = _parsePacketLoss(from: output)
    
                return (latency, packetLoss)
    
            } catch {
    
                NSLog("Failed to execute ping command: \(error)")
    
                return (0.0, 1.0) // Return 0 latency and 100% packet loss on error
    
            }
    
        }
    
    
    
        internal func _parsePingLatency(from output: String) -> Double {
    
            // Example line: round-trip min/avg/max/stddev = 13.596/14.077/14.869/0.502 ms
    
            if let range = output.range(of: "round-trip min/avg/max/stddev = ") {
    
                let statsString = output[range.upperBound...]
    
                let parts = statsString.split(separator: " ")[0].split(separator: "/")
    
                if parts.count >= 2 {
    
                    return Double(parts[1]) ?? 0.0
    
                }
    
            }
    
            return 0.0
    
        }
    
    
    
        internal func _parsePacketLoss(from output: String) -> Double {
    
            // Example line: 5 packets transmitted, 5 packets received, 0.0% packet loss
    
            if let range = output.range(of: "packet loss") {
    
                let prefix = output[..<range.lowerBound]
    
                if let lossRange = prefix.range(of: ", ", options: .backwards) {
    
                     let lossString = prefix[lossRange.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
    
                     if let percentage = Double(lossString.replacingOccurrences(of: "%", with: "")) {
    
                         return percentage / 100.0
    
                     }
    
                }
    
            }
    
            return 1.0 // Assume 100% loss if parsing fails
    
        }
    
    
    
        private func _runShellCommand(_ command: String) async throws -> String {
    
            let process = Process()
    
            process.executableURL = URL(fileURLWithPath: "/bin/bash")
    
            process.arguments = ["-c", command]
    
    
    
            let outputPipe = Pipe()
    
            process.standardOutput = outputPipe
    
    
    
            return try await withCheckedThrowingContinuation { continuation in
    
                do {
    
                    try process.run()
    
                    process.terminationHandler = { process in
    
                        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
    
                        let output = String(data: data, encoding: .utf8) ?? ""
    
                        if process.terminationStatus == 0 {
    
                            continuation.resume(returning: output)
    
                        } else {
    
                            continuation.resume(throwing: NSError(domain: "ShellCommandError", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: "Command failed: \(command)"]))
    
                        }
    
                    }
    
                } catch {
    
                    continuation.resume(throwing: error)
    
                }
    
            }
    
        }
    
    }
    
    