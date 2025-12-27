//
//  NetworkReporterService.swift
//  NetworkReporterService
//
//  Created by Maurice Roach on 22/12/2025.
//

import Foundation

/// This object implements the protocol which we have defined. It provides the actual behavior for the service. It is 'exported' by the service to make it available to the process hosting the service over an NSXPCConnection.
class NetworkReporterService: NSObject, NetworkReporterServiceProtocol {
    
    /// This implements the example protocol. Replace the body of this class with the implementation of this service's protocol.
    @objc func getTimestamp(with reply: @escaping (String?, Error?) -> Void) {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let timestampString = dateFormatter.string(from: Date())
        
        reply(timestampString, nil) // No error for successful timestamp generation
    }
}
