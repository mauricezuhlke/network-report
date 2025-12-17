//
//  main.swift
//  NetworkMonitorAgent
//
//  Created by Maurice Roach on 13/12/2025.
//

import Foundation
import OSLog

// Create a logger for early-stage logging
private let logger = Logger(subsystem: "com.speckit.NetworkMonitorAgent", category: "main")

logger.log("--- NetworkMonitorAgent starting up... ---")

class ServiceDelegate: NSObject, NSXPCListenerDelegate {
    
    /// This method is where the NSXPCListener configures, accepts, and resumes a new incoming NSXPCConnection.
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        
        logger.log("Agent listener accepting new connection.")
        
        // Configure the connection.
        // First, set the interface that the exported object implements.
        newConnection.exportedInterface = NSXPCInterface(with: NetworkMonitorAgentProtocol.self)
        
        // Next, set the object that the connection exports. All messages sent on the connection to this service will be sent to the exported object to handle. The connection retains the exported object.
        let exportedObject = NetworkMonitorAgent()
        newConnection.exportedObject = exportedObject
        
        // Resuming the connection allows the system to deliver more incoming messages.
        newConnection.resume()
        
        logger.log("Agent connection resumed.")
        
        // Returning true from this method tells the system that you have accepted this connection. If you want to reject the connection for some reason, call invalidate() on the connection and return false.
        return true
    }
}

// Create the delegate for the service.
let delegate = ServiceDelegate()

// Set up the one NSXPCListener for this service. It will handle all incoming connections.
let listener = NSXPCListener.service()
listener.delegate = delegate

// Resuming the serviceListener starts this service. This method does not return.
logger.log("Agent listener resuming...")
listener.resume()