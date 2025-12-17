//
//  NetworkMonitorAgentProtocol.swift
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
