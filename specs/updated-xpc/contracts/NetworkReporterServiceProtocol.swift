//
//  NetworkReporterServiceProtocol.swift
//  NetworkReporterService
//
//  Created by Maurice Roach on 22/12/2025.
//

import Foundation

/// The protocol that this service will vend as its API. This protocol will also need to be visible to the process hosting the service.
@objc protocol NetworkReporterServiceProtocol {
    
    /// This function requests the current timestamp from the XPC service.
    /// It returns an ISO 8601 formatted string or an Error.
    func getTimestamp(with reply: @escaping (String?, Error?) -> Void)

    // New methods for Network Performance Monitoring
    func startMonitoring(with reply: @escaping (Error?) -> Void)
    func stopMonitoring(with reply: @escaping (Error?) -> Void)
    func getCurrentPerformance(with reply: @escaping ([String: Any]?, Error?) -> Void) // Placeholder for current metrics
    func updateMonitoringInterval(to interval: Double, with reply: @escaping (Error?) -> Void)
}

/*
 To use the service from an application or other process, use NSXPCConnection to establish a connection to the service by doing something like this:

     let connectionToService = NSXPCConnection(serviceName: "com.example.NetworkReporter.NetworkReporterService")
     connectionToService.remoteObjectInterface = NSXPCInterface(with: NetworkReporterServiceProtocol.self)
     connectionToService.resume()

 Once you have a connection to the service, you can use it like this:

     if let proxy = connectionToService.remoteObjectProxy as? NetworkReporterServiceProtocol {
         proxy.getTimestamp { timestampString, error in
             if let error = error {
                 NSLog("Error from service: \(error)")
             } else if let timestampString = timestampString {
                 NSLog("Timestamp from service: \(timestampString)")
             }
         }
     }

 And, when you are finished with the service, clean up the. connection like this:

     connectionToService.invalidate()
*/
