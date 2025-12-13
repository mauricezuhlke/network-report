//
//  XPCManager.swift
//  SpeckitNetworkMonitor
//
//  Created by Maurice Roach on 13/12/2025.
//

import Foundation
import Combine

class XPCManager: ObservableObject {
    @Published var latestSample: NetworkSampleDTO?
    @Published var connectionStatus: String = "Not Connected"

    private var connection: NSXPCConnection?
    private var agent: NetworkMonitorAgentProtocol?

    func connect() {
        guard connection == nil else {
            connectionStatus = "Already connected"
            return
        }

        // The service name should match the CFBundleIdentifier of the agent service.
        let connection = NSXPCConnection(serviceName: "com.speckit.NetworkMonitorAgent")
        connection.remoteObjectInterface = NSXPCInterface(with: NetworkMonitorAgentProtocol.self)
        
        connection.invalidationHandler = {
            DispatchQueue.main.async {
                self.connectionStatus = "Connection invalidated"
                self.connection = nil
                self.agent = nil
            }
        }
        
        connection.interruptionHandler = {
            DispatchQueue.main.async {
                self.connectionStatus = "Connection interrupted"
            }
        }

        self.connection = connection
        connection.resume()

        self.agent = connection.remoteObjectProxyWithErrorHandler { error in
            DispatchQueue.main.async {
                self.connectionStatus = "Error: \(error.localizedDescription)"
            }
        } as? NetworkMonitorAgentProtocol

        if self.agent != nil {
            DispatchQueue.main.async {
                self.connectionStatus = "Connected"
            }
        }
    }

    func fetchLatestSample() {
        guard let agent = self.agent else {
            connectionStatus = "Not connected to agent"
            return
        }

        agent.fetchLatestSample { [weak self] sample in
            DispatchQueue.main.async {
                self?.latestSample = sample
            }
        }
    }
}
