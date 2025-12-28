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
    @Published var isServiceConnected: Bool = false // Explicitly communicate service connection status
    
    private let persistenceController: PersistenceController
    private var connection: NSXPCConnection?
    private var serviceProxy: NetworkReporterServiceProtocol? // Proxy to the XPC service

    init(persistenceController: PersistenceController) {
        self.persistenceController = persistenceController
        super.init()
        setupConnection()
    }
    
    deinit {
        connection?.invalidate()
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
            }
        } as? NetworkReporterServiceProtocol
        
        // Set connected status after successfully getting proxy
        if serviceProxy != nil {
            DispatchQueue.main.async { self.isServiceConnected = true }
        }
    }
    
    // MARK: - NetworkReporterServiceProtocol (Client calls Service)
    
    func getTimestamp() async throws -> String {
        guard let serviceProxy = serviceProxy else {
            throw XPCClientError.connectionInvalidated
        }
        return try await withCheckedThrowingContinuation { continuation in
            serviceProxy.getTimestamp { timestampString, error in
                if let error = error {
                    continuation.resume(throwing: XPCClientError.serviceReturnedError(error))
                } else if let timestampString = timestampString {
                    continuation.resume(returning: timestampString)
                } else {
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
            serviceProxy.startMonitoring { error in
                if let error = error {
                    continuation.resume(throwing: XPCClientError.serviceReturnedError(error))
                } else {
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
            serviceProxy.stopMonitoring { error in
                if let error = error {
                    continuation.resume(throwing: XPCClientError.serviceReturnedError(error))
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
    
    func getCurrentPerformance() async throws -> [String: Any]? {
        guard let serviceProxy = serviceProxy else {
            throw XPCClientError.serviceDisconnected // More specific error
        }
        return try await withCheckedThrowingContinuation { continuation in
            serviceProxy.getCurrentPerformance { performance, error in
                if let error = error {
                    continuation.resume(throwing: XPCClientError.serviceReturnedError(error))
                } else {
                    continuation.resume(returning: performance)
                }
            }
        }
    }
    
    func getHistoricalPerformance(startDate: Date, endDate: Date) async throws -> [[String: Any]]? {
        guard let serviceProxy = serviceProxy else {
            throw XPCClientError.serviceDisconnected // More specific error
        }
        return try await withCheckedThrowingContinuation { continuation in
            serviceProxy.getHistoricalPerformance(startDate: startDate, endDate: endDate) { historicalData, error in
                if let error = error {
                    continuation.resume(throwing: XPCClientError.serviceReturnedError(error))
                } else {
                    continuation.resume(returning: historicalData)
                }
            }
        }
    }
    
    // MARK: - NetworkReporterClientProtocol (Service calls Client)
    
    func handlePerformanceRecord(_ record: [String: Any]) {
        // This method is called by the XPC service when it has a new performance record
        NSLog("XPCClient received performance record: \(record["timestamp"] ?? "N/A")")
        
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
            }
            
            self.persistenceController.save() // Save the context
        }
    }
}
