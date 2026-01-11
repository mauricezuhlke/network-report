//
//  Persistence.swift
//  NetworkReporter
//
//  Created by Maurice Roach on 22/12/2025.
//

import CoreData

class PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Populate with sample NetworkPerformanceRecord data for preview
        for i in 0..<10 {
            let newRecord = NetworkPerformanceRecord(context: viewContext)
            newRecord.id = UUID()
            newRecord.timestamp = Date().addingTimeInterval(Double(-i * 3600)) // Hourly records
            newRecord.latency = Double.random(in: 20...100)
            newRecord.packetLoss = Double.random(in: 0...0.05)
            newRecord.connectivityStatus = Int16.random(in: 0...1) // 0: Connected, 1: Degraded
            newRecord.uploadSpeed = Double.random(in: 10...50)
            newRecord.downloadSpeed = Double.random(in: 50...200)
        }
        
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "NetworkReporter")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            // Purge old records after stores are loaded
            self.purgeOldRecords()
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    // MARK: - Core Data Saving support
    func save() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    // MARK: - Data Purging
    internal func purgeOldRecords() {
        let eighteenMonthsAgo = Calendar.current.date(byAdding: .month, value: -18, to: Date())!
        let predicate = NSPredicate(format: "timestamp < %@", eighteenMonthsAgo as NSDate)
        
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NetworkPerformanceRecord.fetchRequest()
        fetchRequest.predicate = predicate
        
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        deleteRequest.resultType = .resultTypeObjectIDs
        
        do {
            let result = try container.viewContext.execute(deleteRequest) as? NSBatchDeleteResult
            if let objectIDs = result?.result as? [NSManagedObjectID] {
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: [NSDeletedObjectsKey: objectIDs], into: [container.viewContext])
                NSLog("Purged \(objectIDs.count) old NetworkPerformanceRecord entries.")
            }
        } catch {
            NSLog("Error purging old records: \(error)")
        }
    }

    // MARK: - Core Data Fetching support
    func fetchRecords(for dateInterval: DateInterval) throws -> [NetworkPerformanceRecord] {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<NetworkPerformanceRecord> = NetworkPerformanceRecord.fetchRequest()
        
        fetchRequest.predicate = NSPredicate(format: "timestamp >= %@ AND timestamp <= %@", dateInterval.start as NSDate, dateInterval.end as NSDate)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \NetworkPerformanceRecord.timestamp, ascending: true)]
        
        // Optimization: Use a batch size for efficient fetching
        fetchRequest.fetchBatchSize = 20 // Adjust based on expected data volume
        
        // Optional: set propertiesToFetch if only specific attributes are needed
        // fetchRequest.propertiesToFetch = ["timestamp", "latency", "packetLoss"]
        
        return try context.fetch(fetchRequest)
    }
}
