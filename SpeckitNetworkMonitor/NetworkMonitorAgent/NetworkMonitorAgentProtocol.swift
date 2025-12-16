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
    func getSamples(completion: @escaping (Data) -> Void)
    func getAggregatedSamples(completion: @escaping (Data) -> Void)
    func getStatus(completion: @escaping (String) -> Void)

    // New methods for notification configuration
    func getNotificationConfiguration(completion: @escaping (Data) -> Void)
    func setNotificationConfiguration(_ configuration: Data, completion: @escaping () -> Void)
}