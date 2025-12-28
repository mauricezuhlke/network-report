//
//  NetworkReporterTests.swift
//  NetworkReporterTests
//
//  Created by Maurice Roach on 22/12/2025.
//

import Testing
import CoreData // Import CoreData for testing
@testable import NetworkReporter
@testable import NetworkReporterShared // FIX: For ConnectivityStatus and Protocols
@testable import NetworkReporterService // Import the service for testing

// MARK: - NetworkReporterTests (Existing Tests)
struct NetworkReporterTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

    @Test func testISO8601TimestampFormat() {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let timestampString = dateFormatter.string(from: Date())

        // Regular expression to match ISO 8601 format: YYYY-MM-DDTHH:MM:SS.sssZ
        let iso8601Regex = #"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$"#
        #expect(timestampString.range(of: iso8601Regex, options: .regularExpression) != nil)
    }
}

// MARK: - CoreDataPersistenceTests (Existing Tests)
struct CoreDataPersistenceTests {
    
    // Helper to get an in-memory PersistenceController for testing
    private func setupInMemoryPersistenceController() -> PersistenceController {
        return PersistenceController(inMemory: true)
    }
    
    @Test func testSaveAndFetchNetworkPerformanceRecord() async throws {
        let persistenceController = setupInMemoryPersistenceController()
        let context = persistenceController.container.viewContext
        
        let newRecord = NetworkPerformanceRecord(context: context)
        newRecord.id = UUID()
        newRecord.timestamp = Date()
        newRecord.latency = 50.0
        newRecord.packetLoss = 0.01
        newRecord.connectivityStatus = ConnectivityStatus.connected.rawValue
        newRecord.uploadSpeed = 100.0
        newRecord.downloadSpeed = 500.0
        
        persistenceController.save()
        
        let fetchRequest: NSFetchRequest<NetworkPerformanceRecord> = NetworkPerformanceRecord.fetchRequest()
        let fetchedRecords = try context.fetch(fetchRequest)
        
        #expect(fetchedRecords.count == 1)
        #expect(fetchedRecords.first?.id == newRecord.id)
        #expect(fetchedRecords.first?.latency == newRecord.latency)
    }
    
    @Test func testFetchRecordsForDateRange() async throws {
        let persistenceController = setupInMemoryPersistenceController()
        let context = persistenceController.container.viewContext
        
        // Create records with different timestamps
        let record1 = NetworkPerformanceRecord(context: context)
        record1.id = UUID()
        record1.timestamp = Calendar.current.date(byAdding: .day, value: -5, to: Date())! // 5 days ago
        record1.latency = 10.0
        record1.packetLoss = 0.0
        record1.connectivityStatus = ConnectivityStatus.connected.rawValue
        record1.uploadSpeed = 10.0
        record1.downloadSpeed = 10.0
        
        let record2 = NetworkPerformanceRecord(context: context)
        record2.id = UUID()
        record2.timestamp = Calendar.current.date(byAdding: .day, value: -2, to: Date())! // 2 days ago
        record2.latency = 20.0
        record2.packetLoss = 0.0
        record2.connectivityStatus = ConnectivityStatus.connected.rawValue
        record2.uploadSpeed = 20.0
        record2.downloadSpeed = 20.0
        
        let record3 = NetworkPerformanceRecord(context: context)
        record3.id = UUID()
        record3.timestamp = Date() // Now
        record3.latency = 30.0
        record3.packetLoss = 0.0
        record3.connectivityStatus = ConnectivityStatus.connected.rawValue
        record3.uploadSpeed = 30.0
        record3.downloadSpeed = 30.0
        
        persistenceController.save()
        
        let dateInterval = DateInterval(start: Calendar.current.date(byAdding: .day, value: -3, to: Date())!, end: Date())
        let fetchedRecords = try persistenceController.fetchRecords(for: dateInterval)
        
        #expect(fetchedRecords.count == 2) // Should fetch record2 and record3
        #expect(fetchedRecords.contains(where: { $0.id == record2.id }))
        #expect(fetchedRecords.contains(where: { $0.id == record3.id }))
        #expect(!fetchedRecords.contains(where: { $0.id == record1.id }))
    }
    
    @Test func testPurgeOldRecords() async throws {
        let persistenceController = setupInMemoryPersistenceController()
        let context = persistenceController.container.viewContext
        
        // Create a record older than 18 months
        let oldRecord = NetworkPerformanceRecord(context: context)
        oldRecord.id = UUID()
        oldRecord.timestamp = Calendar.current.date(byAdding: .month, value: -19, to: Date())! // 19 months ago
        oldRecord.latency = 50.0
        oldRecord.packetLoss = 0.01
        oldRecord.connectivityStatus = ConnectivityStatus.connected.rawValue
        oldRecord.uploadSpeed = 100.0
        oldRecord.downloadSpeed = 500.0
        
        // Create a recent record
        let recentRecord = NetworkPerformanceRecord(context: context)
        recentRecord.id = UUID()
        recentRecord.timestamp = Date()
        recentRecord.latency = 50.0
        recentRecord.packetLoss = 0.01
        recentRecord.connectivityStatus = ConnectivityStatus.connected.rawValue
        recentRecord.uploadSpeed = 100.0
        recentRecord.downloadSpeed = 500.0
        
        persistenceController.save()
        
        let fetchRequest: NSFetchRequest<NetworkPerformanceRecord> = NetworkPerformanceRecord.fetchRequest()
        let allRecordsAfterPurge = try context.fetch(fetchRequest)
        
        #expect(allRecordsAfterPurge.count == 1) // Only the recent record should remain
        #expect(allRecordsAfterPurge.first?.id == recentRecord.id)
    }
}

// MARK: - Mock NetworkReporterClientProtocol
class MockNetworkReporterClient: NSObject, NetworkReporterClientProtocol {
    var receivedRecords: [[String: Any]] = []
    
    func handlePerformanceRecord(_ record: [String: Any]) {
        receivedRecords.append(record)
    }
}

// MARK: - NetworkServiceTests
struct NetworkServiceTests {
    @Test func testStartAndStopMonitoring() async throws {
        let service = NetworkReporterService()
        let mockClient = MockNetworkReporterClient()
        service.client = mockClient
        
        var startError: Error?
        await withCheckedContinuation { continuation in
            service.startMonitoring { error in
                startError = error
                continuation.resume()
            }
        }
        #expect(startError == nil)
        // Check if isMonitoring is true (can't directly access private property without reflection/KVC,
        // but we can infer from side effects or check if the timer starts for real impl)
        // For now, rely on XPC method's success.
        
        var stopError: Error?
        await withCheckedContinuation { continuation in
            service.stopMonitoring { error in
                stopError = error
                continuation.resume()
            }
        }
        #expect(stopError == nil)
        // Check if isMonitoring is false
    }
    
    @Test func testGetCurrentPerformance() async throws {
        let service = NetworkReporterService()
        var performance: [String: Any]?
        var error: Error?
        
        await withCheckedContinuation { continuation in
            service.getCurrentPerformance { perf, err in
                performance = perf
                error = err
                continuation.resume()
            }
        }
        
        #expect(error == nil)
        #expect(performance != nil)
        #expect((performance?["latency"] as? Double) != nil)
        #expect((performance?["uploadSpeed"] as? Double) != nil)
    }
    
    @Test func testServiceSendsDataToClient() async throws {
        let service = NetworkReporterService()
        let mockClient = MockNetworkReporterClient()
        service.client = mockClient
        
        var startError: Error?
        await withCheckedContinuation { continuation in
            service.startMonitoring { error in
                startError = error
                continuation.resume()
            }
        }
        #expect(startError == nil)
        
        // Wait for the timer to fire multiple times
        try await Task.sleep(for: .seconds(6)) // Wait for at least one timer fire (5s interval)
        
        #expect(mockClient.receivedRecords.count >= 1) // Expect at least one record
        #expect((mockClient.receivedRecords.first?["latency"] as? Double) != nil)
        
        await withCheckedContinuation { continuation in
            service.stopMonitoring { _ in continuation.resume() }
        }
    }
    
    @Test func testGetHistoricalPerformance() async throws {
        let service = NetworkReporterService()
        let mockClient = MockNetworkReporterClient() // Client to receive data if monitoring runs
        service.client = mockClient
        
        // Start monitoring to populate historical buffer
        await withCheckedContinuation { continuation in
            service.startMonitoring { _ in continuation.resume() }
        }
        try await Task.sleep(for: .seconds(6)) // Let timer fire at least once
        
        let startDate = Calendar.current.date(byAdding: .minute, value: -1, to: Date())!
        let endDate = Date()
        
        var historicalData: [[String: Any]]?
        var error: Error?
        
        await withCheckedContinuation { continuation in
            service.getHistoricalPerformance(startDate: startDate, endDate: endDate) { data, err in
                historicalData = data
                error = err
                continuation.resume()
            }
        }
        
        #expect(error == nil)
        #expect(historicalData != nil)
        #expect(historicalData?.count ?? 0 >= 1) // Expect at least one record
        
        await withCheckedContinuation { continuation in
            service.stopMonitoring { _ in continuation.resume() }
        }
    }
}
