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
    var client: NetworkReporterClientProtocol?

    private var isMonitoring = false
    private var monitoringTimer: Timer?
    private var lastMeasuredPerformance: [String: Any]? // Stores last measured data
    
    // NWPathMonitor for network reachability
    private let pathMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkMonitorQueue")
    private var isConnectedToInternet = false

    override init() {
        super.init()
        setupPathMonitor()
    }
    
    private func setupPathMonitor() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            self?.isConnectedToInternet = (path.status == .satisfied)
            NSLog("Network path status changed: \(path.status == .satisfied ? "Connected" : "Disconnected")")
            // Potentially inform client about connectivity change immediately
        }
        pathMonitor.start(queue: monitorQueue)
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
        NSLog("NetworkReporterService: Monitoring started.")

        // Invalidate any existing timer
        monitoringTimer?.invalidate()
        // Start a timer to periodically call _measureNetworkPerformance()
        // Ensure timer runs on a background thread/runloop to not block XPC
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let record = self._measureNetworkPerformance()
            self.lastMeasuredPerformance = record
            NSLog("NetworkReporterService: Measured performance record: \(record["timestamp"] ?? "N/A"), client is nil: \(self.client == nil)")
            if self.client == nil {
                NSLog("NetworkReporterService: Client proxy is nil. Cannot send performance record.")
            }
            // Send the record to the client
            self.client?.handlePerformanceRecord(record)
        }
        RunLoop.current.add(monitoringTimer!, forMode: .common) // Ensure timer works with XPC
        reply(nil)
    }

    @objc func stopMonitoring(with reply: @escaping (Error?) -> Void) {
        guard isMonitoring else {
            reply(nil) // Not monitoring
            return
        }
        isMonitoring = false
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        NSLog("NetworkReporterService: Monitoring stopped.")
        reply(nil)
    }

    @objc func getCurrentPerformance(with reply: @escaping ([String: Any]?, Error?) -> Void) {
        // Return the last measured performance if available, otherwise measure on demand
        if let last = lastMeasuredPerformance {
            reply(last, nil)
        } else {
            let currentMetrics = _measureNetworkPerformance()
            self.lastMeasuredPerformance = currentMetrics
            reply(currentMetrics, nil)
        }
    }



    // Placeholder for actual network performance measurement
    private func _measureNetworkPerformance() -> [String: Any] {
        var latency = 0.0
        var packetLoss = 0.0
        var connectivityStatus: Int16 = ConnectivityStatus.disconnected.rawValue // Default disconnected
        var uploadSpeed = 0.0
        var downloadSpeed = 0.0
        
        if isConnectedToInternet {
            latency = Double.random(in: 20...150)
            packetLoss = Double.random(in: 0...0.02)
            connectivityStatus = (latency > 100 || packetLoss > 0.01) ? ConnectivityStatus.degraded.rawValue : ConnectivityStatus.connected.rawValue
            uploadSpeed = Double.random(in: 10...80) // Mbps
            downloadSpeed = Double.random(in: 50...500) // Mbps
        } else {
            // Simulate disconnected state
            latency = 9999.0 // Very high latency
            packetLoss = 1.0 // 100% packet loss
            connectivityStatus = ConnectivityStatus.disconnected.rawValue
            // Speeds remain 0.0
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

        return record
    }
}