//
//  XPCClient.swift
//  NetworkReporter
//
//  Created by Maurice Roach on 22/12/2025.
//

import Foundation

enum XPCClientError: Error, LocalizedError {
    case connectionFailed
    case serviceReturnedError(Error)
    case unexpectedResponse
    case proxyCreationFailed
    
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
        }
    }
}

class XPCClient {

    init() {
        // No persistent connection setup here
    }

    func getTimestamp() async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
        // Service name must match the one defined in the XPC service's Info.plist - maro.NetworkReporterService - DO NOT CHANGE!!!
            let connection = NSXPCConnection(serviceName: "maro.NetworkReporterService")
            connection.remoteObjectInterface = NSXPCInterface(with: NetworkReporterServiceProtocol.self)
            
            var didResume = false
            
            let resumeOnce: (Result<String, Error>) -> Void = { result in
                if !didResume {
                    didResume = true
                    switch result {
                    case .success(let value):
                        continuation.resume(returning: value)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }

            // Set invalidationHandler BEFORE resuming connection to catch immediate failures
            connection.invalidationHandler = { [connection] in
                resumeOnce(.failure(XPCClientError.connectionFailed))
                connection.invalidate()
            }
            
            connection.resume()

            guard let proxy = connection.remoteObjectProxy as? NetworkReporterServiceProtocol else {
                connection.invalidate()
                resumeOnce(.failure(XPCClientError.proxyCreationFailed))
                return
            }

            proxy.getTimestamp { timestampString, error in
                defer { connection.invalidate() } // Always invalidate the connection when the call completes

                if let error = error {
                    resumeOnce(.failure(XPCClientError.serviceReturnedError(error)))
                } else if let timestampString = timestampString {
                    resumeOnce(.success(timestampString))
                } else {
                    resumeOnce(.failure(XPCClientError.unexpectedResponse))
                }
            }
        }
    }
}
