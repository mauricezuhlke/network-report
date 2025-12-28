//
//  NetworkChartViewModel.swift
//  NetworkReporter
//
//  Created by Maurice Roach on 22/12/2025.
//

import Foundation
import CoreData
import Combine
import NetworkReporterShared // FIX: For ConnectivityStatus enum

enum TimeRange: String, CaseIterable, Identifiable, CustomStringConvertible {
    case lastHour = "Last Hour"
    case last24Hours = "Last 24 Hours"
    case last7Days = "Last 7 Days"
    case last30Days = "Last 30 Days"

    var id: String { self.rawValue }

    var description: String { self.rawValue }

    var dateInterval: DateInterval {
        let now = Date()
        var startDate: Date
        switch self {
        case .lastHour:
            startDate = Calendar.current.date(byAdding: .hour, value: -1, to: now)!
        case .last24Hours:
            startDate = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        case .last7Days:
            startDate = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        case .last30Days:
            startDate = Calendar.current.date(byAdding: .day, value: -30, to: now)!
        }
        return DateInterval(start: startDate, end: now)
    }
}

class NetworkChartViewModel: ObservableObject {
    @Published var historicalRecords: [NetworkPerformanceRecord] = []
    @Published var selectedTimeRange: TimeRange = .last24Hours
    @Published var errorMessage: String?
    
    private var viewContext: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()

    init(context: NSManagedObjectContext) {
        self.viewContext = context
    }
    
    func fetchHistoricalRecords() {
        let dateInterval = selectedTimeRange.dateInterval
        
        do {
            historicalRecords = try PersistenceController.shared.fetchRecords(for: dateInterval)
            errorMessage = nil
        } catch {
            errorMessage = "Error fetching historical data: \(error.localizedDescription)"
            NSLog(errorMessage!)
        }
    }
    
    // Logic for identifying and marking degradation periods based on defined thresholds
    func isRecordDegraded(_ record: NetworkPerformanceRecord) -> Bool {
        return record.latency > 200.0 || record.packetLoss > 0.05 || record.connectivityStatus_ == .disconnected
    }

    // You could also provide a computed property to filter degraded records
    var degradedRecords: [NetworkPerformanceRecord] {
        return historicalRecords.filter { isRecordDegraded($0) }
    }
}
