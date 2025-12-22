//
//  NetworkReporterServiceProtocol.swift
//  NetworkReporterService
//
//  Created by Maurice Roach on 22/12/2025.
//

import Foundation

/// The protocol that this service will vend as its API. This protocol will also need to be visible to the process hosting the service.
@objc protocol NetworkReporterServiceProtocol {
    
    /// This function returns the current timestamp from the XPC service.
    func getTimestamp(with reply: @escaping (Date) -> Void)
}

/*
 To use the service from an application or other process, use NSXPCConnection to establish a connection to the service by doing something like this:

     connectionToService = NSXPCConnection(serviceName: "maro.NetworkReporterService")
     connectionToService.remoteObjectInterface = NSXPCInterface(with: (any NetworkReporterServiceProtocol).self)
     connectionTo-service.resume()

 Once you have a connection to the service, you can use it like this:

     if let proxy = connectionToService.remoteObjectProxy as? NetworkReporterServiceProtocol {
         proxy.getTimestamp { timestamp in
             NSLog("Timestamp from service: \(timestamp)")
         }
     }

 And, when you are finished with the service, clean up the connection like this:

     connectionToService.invalidate()
*/