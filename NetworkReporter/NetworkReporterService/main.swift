//
//  main.swift
//  NetworkReporterService
//
//  Created by Maurice Roach on 22/12/2025.
//

import Foundation
import NetworkReporterShared // FIX: For NetworkReporterServiceProtocol and NetworkReporterClientProtocol

class ServiceDelegate: NSObject, NSXPCListenerDelegate {
    
    /// This method is where the NSXPCListener configures, accepts, and resumes a new incoming NSXPCConnection.
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        
        // Configure the connection.
        // First, set the interface that the exported object implements.
        newConnection.exportedInterface = NSXPCInterface(with: (any NetworkReporterServiceProtocol).self)
        
        // Next, set the object that the connection exports. All messages sent on the connection to this service will be sent to the exported object to handle. The connection retains the exported object.
        let exportedObject = NetworkReporterService()
        newConnection.exportedObject = exportedObject
        
        // Also, set the interface that the *client* exports (for reverse communication).
        newConnection.remoteObjectInterface = NSXPCInterface(with: (any NetworkReporterClientProtocol).self)

        // Obtain the proxy to the client's exported object and provide it to the service.
        exportedObject.client = newConnection.remoteObjectProxyWithErrorHandler { error in
            NSLog("Error accessing client proxy: \(error)")
        } as? NetworkReporterClientProtocol
        
        // After setting the client, register it with the service.
        exportedObject.registerClient()
        
        // Resuming the connection allows the system to deliver more incoming messages.
        newConnection.resume()
        
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
listener.resume()