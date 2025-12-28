//
//  NetworkReporterShared.swift
//  NetworkReporterShared
//
//  Created by Maurice Roach on 22/12/2025.
//

import Foundation

// MARK: - ConnectivityStatus Enum
public enum ConnectivityStatus: Int16, CaseIterable, Identifiable, CustomStringConvertible {
    case connected = 0
    case degraded = 1
    case disconnected = 2

    public var id: Self { self }

    public var description: String {
        switch self {
        case .connected: return "Connected"
        case .degraded: return "Degraded"
        case .disconnected: return "Disconnected"
        }
    }
}

// MARK: - NetworkReporterServiceProtocol (Client calls Service)
/// The protocol that this service will vend as its API. This protocol will also need to be visible to the process hosting the service.
@objc public protocol NetworkReporterServiceProtocol {
    
    /// This function requests the current timestamp from the XPC service.
    /// It returns an ISO 8601 formatted string or an Error.
    func getTimestamp(with reply: @escaping (String?, Error?) -> Void)

    // New methods for Network Performance Monitoring
    func startMonitoring(with reply: @escaping (Error?) -> Void)
    func stopMonitoring(with reply: @escaping (Error?) -> Void)
    func getCurrentPerformance(with reply: @escaping ([String: Any]?, Error?) -> Void) // Placeholder for current metrics
    func getHistoricalPerformance(startDate: Date, endDate: Date, with reply: @escaping ([[String: Any]]?, Error?) -> Void) // Placeholder for historical metrics
}

// MARK: - NetworkReporterClientProtocol (Service calls Client)
@objc public protocol NetworkReporterClientProtocol {
    func handlePerformanceRecord(_ record: [String: Any])
}
