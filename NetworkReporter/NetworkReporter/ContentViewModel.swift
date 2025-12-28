//
//  ContentViewModel.swift
//  NetworkReporter
//
//  Created by Maurice Roach on 22/12/2025.
//

import Foundation
import Combine
import CoreData // If CoreData is used directly in ViewModel, otherwise remove
import NetworkReporterShared // FIX: For ConnectivityStatus.description

class ContentViewModel: ObservableObject {
    @Published var realTimeRecord: NetworkPerformanceRecord?
    @Published var connectionStatus: String = "Connecting..."
    @Published var errorMessage: String?
    
    private var xpcClientCancellable: AnyCancellable?
    
    init() {
        // Initialize with default states
    }
    
    // This method should be called when XPCClient becomes available, e.g., from ContentView's .onAppear
    func observeXPCClient(_ client: XPCClient) {
        guard xpcClientCancellable == nil else { return } // Avoid setting up multiple observers
        xpcClientCancellable = client.$latestPerformanceRecord
            .receive(on: DispatchQueue.main)
            .sink { [weak self] record in
                self?.realTimeRecord = record
                if let record = record {
                    self?.connectionStatus = record.connectivityStatus_.description
                } else {
                    self?.connectionStatus = "No data yet"
                }
            }
    }
    
    // Expose a method for ContentView to request latest data if needed (e.g., pull to refresh)
    // For real-time, observation is sufficient, but this might be useful for explicit refresh.
    func refreshRealTimeData(xpcClient: XPCClient) {
        Task {
            do {
                _ = try await xpcClient.getCurrentPerformance()
                // The XPCClient's handlePerformanceRecord already updates latestPerformanceRecord.
                // This call ensures the XPCClient fetches the latest from the service.
                NSLog("Refreshed real-time data from XPC service.")
            } catch {
                DispatchQueue.main.async { self.errorMessage = error.localizedDescription }
            }
        }
    }
}