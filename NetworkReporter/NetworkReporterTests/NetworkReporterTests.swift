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
        oldRecord.timestamp = Calendar.current.date(byAdding: .month, value: -19, to: Date())!
        
        // Create a recent record
        let recentRecord = NetworkPerformanceRecord(context: context)
        recentRecord.id = UUID()
        recentRecord.timestamp = Date()
        
        // Save both records
        persistenceController.save()
        
        // Explicitly call the purge function to test it
        persistenceController.purgeOldRecords()
        
        // Fetch remaining records
        let fetchRequest: NSFetchRequest<NetworkPerformanceRecord> = NetworkPerformanceRecord.fetchRequest()
        let allRecordsAfterPurge = try context.fetch(fetchRequest)
        
        #expect(allRecordsAfterPurge.count == 1) // Only the recent record should remain
        #expect(allRecordsAfterPurge.first?.id == recentRecord.id)
    }
}

// MARK: - NetworkReporterServiceTests (New Tests)
struct NetworkReporterServiceTests {
    let service = NetworkReporterService()

    @Test func testParsePingLatency() {
        let normalOutput = "round-trip min/avg/max/stddev = 13.596/14.077/14.869/0.502 ms"
        let zeroOutput = "round-trip min/avg/max/stddev = 0/0/0/0 ms"
        let noOutput = "some other random string"
        
        let latency1 = service._parsePingLatency(from: normalOutput)
        #expect(latency1 == 14.077)
        
        let latency2 = service._parsePingLatency(from: zeroOutput)
        #expect(latency2 == 0)
        
        let latency3 = service._parsePingLatency(from: noOutput)
        #expect(latency3 == 0.0)
    }

    @Test func testParsePacketLoss() {
        let normalOutput = "5 packets transmitted, 5 packets received, 0.0% packet loss"
        let lossOutput = "10 packets transmitted, 8 received, 20.0% packet loss"
        let hundredPercentLoss = "5 packets transmitted, 0 received, 100.0% packet loss"
        let noOutput = "some other random string"

        let loss1 = service._parsePacketLoss(from: normalOutput)
        #expect(loss1 == 0.0)

        let loss2 = service._parsePacketLoss(from: lossOutput)
        #expect(loss2 == 0.2)

        let loss3 = service._parsePacketLoss(from: hundredPercentLoss)
        #expect(loss3 == 1.0)

        let loss4 = service._parsePacketLoss(from: noOutput)
        #expect(loss4 == 1.0) // Should default to 100% loss if parsing fails
    }
}


// MARK: - Mock NetworkReporterClientProtocol
class MockNetworkReporterClient: NSObject, NetworkReporterClientProtocol {
    var receivedRecords: [[String: Any]] = []
    
    func handlePerformanceRecord(_ record: [String: Any]) {
        receivedRecords.append(record)
    }
}