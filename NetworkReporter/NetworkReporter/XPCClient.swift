//
//  XPCClient.swift
//  NetworkReporter
//
//  Created by Maurice Roach on 22/12/2025.
//

import Foundation
import CoreData // For saving to CoreData
import Combine // FIX: For @Published
import NetworkReporterShared // FIX: For NetworkReporterClientProtocol and NetworkReporterServiceProtocol

enum XPCClientError: Error, LocalizedError {
    case connectionFailed
    case serviceReturnedError(Error)
    case unexpectedResponse
    case proxyCreationFailed
    case connectionInvalidated
    case serviceDisconnected
    
    var errorDescription: String? {
        switch self {
        case .connectionFailed:
            return "Failed to establish connection to XPC service or connection became invalid."
        case .serviceReturnedError(let error):
            return "XPC service returned an error: \(error.localizedDescription)"
        case .unexpectedResponse:
            return "Received an unexpected response from the XPC service."
        case .proxyCreationFailed:
            return "Failed to create remote object proxy for XPC service."
        case .connectionInvalidated:
            return "XPC connection has been invalidated."
        case .serviceDisconnected:
            return "XPC service is disconnected."
        }
    }
}

// MARK: - XPCClient (implements NetworkReporterClientProtocol)
final class XPCClient: NSObject, NetworkReporterClientProtocol, ObservableObject { // FIX: Make final for ObservableObject conformance
    
    // Publish updates for SwiftUI views
    @Published var latestPerformanceRecord: NetworkPerformanceRecord?
    @Published var recentPerformanceRecords: [NetworkPerformanceRecord] = [] // Stores a history of records for charts
    @Published var isServiceConnected: Bool = false // Explicitly communicate service connection status
    @Published var monitoringInterval: Double = UserDefaults.standard.double(forKey: "monitoringInterval") {
        didSet {
            // Inform the XPC service immediately if the interval changes
            Task { await self.updateMonitoringInterval(to: self.monitoringInterval) }
        }
    }
    @Published var currentError: Error? // New property to publish errors to the UI

    private let persistenceController: PersistenceController
    private var connection: NSXPCConnection?
    private var serviceProxy: NetworkReporterServiceProtocol? // Proxy to the XPC service
    private var monitoringIntervalCancellable: AnyCancellable?
    private let maxRecentRecords = 60 // Keep last 60 records for charts (e.g., 5 minutes at 5-second interval)

    init(persistenceController: PersistenceController) {
        self.persistenceController = persistenceController
        super.init()
        setupConnection()
        setupMonitoringIntervalObservation()
    }
    
    deinit {
        connection?.invalidate()
        monitoringIntervalCancellable?.cancel()
    }
    
    private func setupConnection() {
        connection = NSXPCConnection(serviceName: "maro.NetworkReporterService")
        
        // Configure the remote object interface for the service (what we call on the service)
        connection?.remoteObjectInterface = NSXPCInterface(with: NetworkReporterServiceProtocol.self)
        
        // Configure the exported object interface for our client (what the service calls on us)
        connection?.exportedInterface = NSXPCInterface(with: NetworkReporterClientProtocol.self)
        connection?.exportedObject = self // XPCClient itself acts as the exported object
        
        connection?.interruptionHandler = { [weak self] in
            NSLog("XPC Connection Interrupted")
            DispatchQueue.main.async {
                self?.serviceProxy = nil
                self?.isServiceConnected = false
                self?.latestPerformanceRecord = nil // Clear data if service is interrupted
                self?.recentPerformanceRecords = []
                self?.currentError = XPCClientError.connectionInvalidated // Set error
            }
            // Invalidate the connection if interrupted to allow for a fresh start or proper error handling
            self?.connection?.invalidate()
            self?.connection = nil
        }
        
        connection?.invalidationHandler = { [weak self] in
            NSLog("XPC Connection Invalidated")
            DispatchQueue.main.async {
                self?.serviceProxy = nil
                self?.isServiceConnected = false
                self?.latestPerformanceRecord = nil // Clear data if service is invalidated
                self?.recentPerformanceRecords = []
                self?.currentError = XPCClientError.connectionInvalidated // Set error
            }
            // Handle cleanup, potentially attempt to reconnect after a delay
            self?.connection?.invalidate() // Ensure cleanup
            self?.connection = nil
        }
        
        connection?.resume()
        
        // Get the proxy to the XPC service
        serviceProxy = connection?.remoteObjectProxyWithErrorHandler { [weak self] error in
            NSLog("Remote object proxy error: \(error)")
            DispatchQueue.main.async {
                self?.serviceProxy = nil
                self?.isServiceConnected = false
                self?.latestPerformanceRecord = nil // Clear data if service is down
                self?.recentPerformanceRecords = []
                self?.currentError = XPCClientError.proxyCreationFailed // Set error based on proxy failure
            }
        } as? NetworkReporterServiceProtocol
        
        // Set connected status after successfully getting proxy
        if serviceProxy != nil {
            DispatchQueue.main.async { self.isServiceConnected = true }
            // Immediately send the current interval to the service
            Task { await self.updateMonitoringInterval(to: self.monitoringInterval) }
        }
    }
    
    private func setupMonitoringIntervalObservation() {
        // Observe changes to the monitoringInterval in UserDefaults
        // Note: @AppStorage writes to UserDefaults.standard
        monitoringIntervalCancellable = UserDefaults.standard
            .publisher(for: \.monitoringInterval) // Assuming monitoringInterval is a registered key
            .sink { [weak self] newInterval in
                DispatchQueue.main.async {
                    self?.monitoringInterval = newInterval
                    // The didSet of monitoringInterval will trigger the XPC service update
                }
            }
    }
    
    // MARK: - NetworkReporterServiceProtocol (Client calls Service)
    
    func getTimestamp() async throws -> String {
        guard let serviceProxy = serviceProxy else {
            throw XPCClientError.connectionInvalidated
        }
        return try await withCheckedThrowingContinuation { continuation in
            serviceProxy.getTimestamp { [weak self] timestampString, error in
                if let error = error {
                    DispatchQueue.main.async { self?.currentError = XPCClientError.serviceReturnedError(error) }
                    continuation.resume(throwing: XPCClientError.serviceReturnedError(error))
                } else if let timestampString = timestampString {
                    continuation.resume(returning: timestampString)
                } else {
                    DispatchQueue.main.async { self?.currentError = XPCClientError.unexpectedResponse }
                    continuation.resume(throwing: XPCClientError.unexpectedResponse)
                }
            }
        }
    }
    
    func startMonitoring() async throws {
        guard let serviceProxy = serviceProxy else {
            throw XPCClientError.serviceDisconnected // More specific error
        }
        return try await withCheckedThrowingContinuation { continuation in
            serviceProxy.startMonitoring { [weak self] error in
                if let error = error {
                    DispatchQueue.main.async { self?.currentError = XPCClientError.serviceReturnedError(error) }
                    continuation.resume(throwing: XPCClientError.serviceReturnedError(error))
                } else {
                    self?.currentError = nil // Clear error on success
                    continuation.resume(returning: ())
                }
            }
        }
    }
    
    func stopMonitoring() async throws {
        guard let serviceProxy = serviceProxy else {
            throw XPCClientError.serviceDisconnected // More specific error
        }
        return try await withCheckedThrowingContinuation { continuation in
            serviceProxy.stopMonitoring { [weak self] error in
                if let error = error {
                    DispatchQueue.main.async { self?.currentError = XPCClientError.serviceReturnedError(error) }
                    continuation.resume(throwing: XPCClientError.serviceReturnedError(error))
                } else {
                    self?.currentError = nil // Clear error on success
                    continuation.resume(returning: ())
                }
            }
        }
    }
    
    func updateMonitoringInterval(to interval: Double) async {
        guard let serviceProxy = serviceProxy else {
            NSLog("XPCClient: Service disconnected, cannot update monitoring interval.")
            DispatchQueue.main.async { self.currentError = XPCClientError.serviceDisconnected }
            return
        }
        return await withCheckedContinuation { continuation in
            serviceProxy.updateMonitoringInterval(to: interval) { [weak self] error in
                if let error = error {
                    NSLog("XPCClient: Error updating monitoring interval: \(error.localizedDescription)")
                    DispatchQueue.main.async { self?.currentError = XPCClientError.serviceReturnedError(error) }
                } else {
                    NSLog("XPCClient: Monitoring interval updated to \(interval)s.")
                    self?.currentError = nil // Clear error on success
                }
                continuation.resume(returning: ())
            }
        }
    }
    
    func getCurrentPerformance() async throws -> [String: Any]? {
        guard let serviceProxy = serviceProxy else {
            throw XPCClientError.serviceDisconnected // More specific error
        }
        return try await withCheckedThrowingContinuation { continuation in
            serviceProxy.getCurrentPerformance { [weak self] performance, error in
                if let error = error {
                    DispatchQueue.main.async { self?.currentError = XPCClientError.serviceReturnedError(error) }
                    continuation.resume(throwing: XPCClientError.serviceReturnedError(error))
                } else {
                    self?.currentError = nil // Clear error on success
                    continuation.resume(returning: performance)
                }
            }
        }
    }
    
    // Now fetches directly from PersistenceController as XPC Service no longer holds historical data
    func getHistoricalPerformance(startDate: Date, endDate: Date) async throws -> [[String: Any]]? {
        // Clear any previous errors before a new operation
        DispatchQueue.main.async { self.currentError = nil }
        
        let dateInterval = DateInterval(start: startDate, end: endDate) // Convert Range<Date> to DateInterval
        do {
            let records = try persistenceController.fetchRecords(for: dateInterval) // Mark as try since fetchRecords can throw
            return records.map { record in
                // Map NetworkPerformanceRecord (CoreData object) to a dictionary
                // This should mirror the structure returned by _measureNetworkPerformance in the service
                return [
                    "id": record.id?.uuidString ?? UUID().uuidString,
                    "timestamp": record.timestamp ?? Date(),
                    "latency": record.latency,
                    "packetLoss": record.packetLoss,
                    "connectivityStatus": record.connectivityStatus,
                    "uploadSpeed": record.uploadSpeed,
                    "downloadSpeed": record.downloadSpeed
                ]
            }
        } catch {
            DispatchQueue.main.async { self.currentError = error }
            throw error
        }
    }
    
    // MARK: - NetworkReporterClientProtocol (Service calls Client)
    
    func handlePerformanceRecord(_ record: [String: Any]) {
        // This method is called by the XPC service when it has a new performance record
        NSLog("XPCClient: handlePerformanceRecord called, timestamp: \(record["timestamp"] ?? "N/A")")
        // NOTE: Commenting out the duplicate NSLog
        // NSLog("XPCClient received performance record: \(record["timestamp"] ?? "N/A")")
        
        // Save to CoreData
        let context = persistenceController.container.viewContext
        context.perform {
            let newRecord = NetworkPerformanceRecord(context: context)
            newRecord.id = UUID(uuidString: record["id"] as? String ?? UUID().uuidString)
            newRecord.timestamp = record["timestamp"] as? Date
            newRecord.latency = record["latency"] as? Double ?? 0.0
            newRecord.packetLoss = record["packetLoss"] as? Double ?? 0.0
            newRecord.connectivityStatus = record["connectivityStatus"] as? Int16 ?? ConnectivityStatus.disconnected.rawValue
            newRecord.uploadSpeed = record["uploadSpeed"] as? Double ?? 0.0
            newRecord.downloadSpeed = record["downloadSpeed"] as? Double ?? 0.0
            
            // Publish the latest record for SwiftUI
            // Need to ensure this runs on main thread for @Published
            DispatchQueue.main.async {
                self.latestPerformanceRecord = newRecord
                // Append to recent records and trim
                self.recentPerformanceRecords.append(newRecord)
                if self.recentPerformanceRecords.count > self.maxRecentRecords {
                    self.recentPerformanceRecords.removeFirst(self.recentPerformanceRecords.count - self.maxRecentRecords)
                }
                self.currentError = nil // Clear error on successful record handling
            }
            
            self.persistenceController.save() // Save the context
        }
    }
}

// Extension to make monitoringInterval observable via KVO (for UserDefaults publisher)
// This is necessary because UserDefaults.standard.publisher(for:keyPath:) expects the keyPath to an Objective-C KVO-compliant property.
extension UserDefaults {
    @objc dynamic var monitoringInterval: Double {
        return double(forKey: "monitoringInterval")
    }
}