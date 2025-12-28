//
//  NetworkPerformanceRecord+CoreData.swift
//  NetworkReporter
//
//  Created by Maurice Roach on 22/12/2025.
//

import Foundation
import CoreData
import NetworkReporterShared // FIX: For ConnectivityStatus enum

extension NetworkPerformanceRecord {
    // Convenience properties for CoreData attributes
    public var id_: UUID {
        get { id ?? UUID() }
        set { id = newValue }
    }

    public var timestamp_: Date {
        get { timestamp ?? Date() }
        set { timestamp = newValue }
    }

    public var connectivityStatus_: ConnectivityStatus {
        get { ConnectivityStatus(rawValue: connectivityStatus) ?? .disconnected }
        set { connectivityStatus = newValue.rawValue }
    }

    // Example helper method (add more as needed)
    public var isDegraded: Bool {
        return connectivityStatus_ == .degraded || packetLoss > 0.05 // Example threshold
    }
}
