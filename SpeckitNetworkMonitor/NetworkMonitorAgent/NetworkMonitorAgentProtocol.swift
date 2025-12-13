//
//  NetworkMonitorAgentProtocol.swift
//  NetworkMonitorAgent
//
//  Created by Maurice Roach on 13/12/2025.
//

import Foundation

// A simple Codable struct for transferring network data across the XPC boundary.
struct NetworkSampleDTO: Codable {
    let timestamp: Date
    let latency: Double // in milliseconds
    let jitter: Double // in milliseconds
    let packetLoss: Double // as a percentage (0.0 to 100.0)
}


/// The protocol that this service will vend as its API. This protocol will also need to be visible to the process hosting the service.
@objc protocol NetworkMonitorAgentProtocol {

    /// Fetches the most recent network sample.
    /// - Parameter reply: A closure that receives the most recent `NetworkSampleDTO` or `nil` if none is available.
    func fetchLatestSample(with reply: @escaping (NetworkSampleDTO?) -> Void)

    /// Fetches an array of network samples for a given date range.
    /// - Parameters:
    ///   - startDate: The start of the date range.
    ///   - endDate: The end of the date range.
    ///   - reply: A closure that receives an array of `NetworkSampleDTO` objects.
    func fetchSamples(from startDate: Date, to endDate: Date, with reply: @escaping ([NetworkSampleDTO]) -> Void)
}

/*
 To use the service from an application or other process, use NSXPCConnection to establish a connection to the service by doing something like this:

     let connection = NSXPCConnection(serviceName: "com.speckit.NetworkMonitorAgent")
     connection.remoteObjectInterface = NSXPCInterface(with: NetworkMonitorAgentProtocol.self)
     connection.resume()

 Once you have a connection to the service, you can use it like this:

     if let proxy = connection.remoteObjectProxy as? NetworkMonitorAgentProtocol {
         proxy.fetchLatestSample { sample in
             if let sample = sample {
                 print("Latest sample: \(sample.latency)ms")
             }
         }
     }

 And, when you are finished with the service, clean up the connection like this:

     connection.invalidate()
*/
