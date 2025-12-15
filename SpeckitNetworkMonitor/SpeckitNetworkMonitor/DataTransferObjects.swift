//
//  DataTransferObjects.swift
//  SpeckitNetworkMonitor
//
//  Created by Maro on 2025-12-14.
//

import Foundation

@objc public protocol NetworkMonitorAgentProtocol {
    func startMonitoring()
    func stopMonitoring()
    func getStatus(completion: @escaping (String) -> Void)

    func fetchLatestSample(completion: @escaping (Data?) -> Void)
    func fetchSamples(from startDate: Date, to endDate: Date, completion: @escaping (Data) -> Void)
    func fetchAggregatedSamples(from startDate: Date, to endDate: Date, intervalType: String, metricType: String, completion: @escaping (Data) -> Void)
    func updateNotificationConfiguration(configuration: Data)
}

public struct NetworkSampleDTO: Codable, Identifiable {
    public var id: Date { timestamp }
    public let timestamp: Date
    public let latency: TimeInterval
    public let packetLoss: Double
    public let connectivity: Bool
}

public struct AggregatedSeriesDTO: Codable, Identifiable {
    public var id = UUID()
    public let metric: String // e.g., "Latency", "Packet Loss"
    public let data: [GraphPoint]
}

public struct GraphPoint: Codable {
    public let date: Date
    public let value: Double
}


public struct NotificationConfigurationDTO: Codable {
    public var isEnabled: Bool
    public var latencyThreshold: Double
    public var packetLossThreshold: Double
    public var consecutiveFailuresThreshold: Int
}
