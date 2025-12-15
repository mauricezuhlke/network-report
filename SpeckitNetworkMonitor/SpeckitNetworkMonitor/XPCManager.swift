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
    @Published var historicalSamples: [NetworkSampleDTO] = []
    
    // New published variables for aggregated data
    @Published var aggregatedLatencySeries: [AggregatedSeriesDTO] = []
    @Published var aggregatedJitterSeries: [AggregatedSeriesDTO] = []
    @Published var aggregatedPacketLossSeries: [AggregatedSeriesDTO] = []
    @Published var aggregatedDownloadSeries: [AggregatedSeriesDTO] = [] // New
    @Published var aggregatedUploadSeries: [AggregatedSeriesDTO] = [] // New
    
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
    
    func invalidate() {
        connection?.invalidate()
        connection = nil
        agent = nil
    }

    func fetchLatestSample() {
        guard let agent = self.agent else {
            connectionStatus = "Not connected to agent"
            return
        }

        agent.fetchLatestSample { [weak self] data in
            guard let data = data else {
                DispatchQueue.main.async {
                    self?.latestSample = nil
                }
                return
            }
            do {
                let sample = try JSONDecoder().decode(NetworkSampleDTO.self, from: data)
                DispatchQueue.main.async {
                    self?.latestSample = sample
                }
            } catch {
                print("Error decoding latest sample: \(error)")
            }
        }
    }
    
    func fetchSamples(from startDate: Date, to endDate: Date) {
        guard let agent = self.agent else {
            connectionStatus = "Not connected to agent"
            return
        }
        
        agent.fetchSamples(from: startDate, to: endDate) { [weak self] data in
            do {
                let samples = try JSONDecoder().decode([NetworkSampleDTO].self, from: data)
                DispatchQueue.main.async {
                    self?.historicalSamples = samples
                }
            } catch {
                print("Error decoding historical samples: \(error)")
            }
        }
    }
    
    func fetchAggregatedSamples(from startDate: Date, to endDate: Date, intervalType: String, metricType: String) {
        guard let agent = self.agent else {
            connectionStatus = "Not connected to agent"
            return
        }
        
        agent.fetchAggregatedSamples(from: startDate, to: endDate, intervalType: intervalType, metricType: metricType) { [weak self] data in
            do {
                let samples = try JSONDecoder().decode([AggregatedSeriesDTO].self, from: data)
                DispatchQueue.main.async {
                    switch metricType {
                    case "latency":
                        self?.aggregatedLatencySeries = samples
                    case "jitter":
                        self?.aggregatedJitterSeries = samples
                    case "packetLoss":
                        self?.aggregatedPacketLossSeries = samples
                    case "download":
                        self?.aggregatedDownloadSeries = samples
                    case "upload":
                        self?.aggregatedUploadSeries = samples
                    default:
                        break
                    }
                }
            } catch {
                print("Error decoding aggregated samples: \(error)")
            }
        }
    }
    
    func updateNotificationConfiguration(configuration: NotificationConfigurationDTO) {
        guard let agent = self.agent else {
            connectionStatus = "Not connected to agent"
            return
        }
        do {
            let data = try JSONEncoder().encode(configuration)
            agent.updateNotificationConfiguration(configuration: data)
        } catch {
            print("Error encoding notification configuration: \(error)")
        }
    }
}
