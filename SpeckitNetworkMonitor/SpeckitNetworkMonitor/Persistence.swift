//
//  Persistence.swift
//  SpeckitNetworkMonitor
//
//  Created by Maurice Roach on 13/12/2025.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for i in 0..<10 {
            let newSample = NetworkSample(context: viewContext)
            newSample.timestamp = Date().addingTimeInterval(Double(i) * -60) // Go back in time
            newSample.latency_avg = Double.random(in: 20...150)
            newSample.latency_min = newSample.latency_avg - Double.random(in: 5...10)
            newSample.latency_max = newSample.latency_avg + Double.random(in: 5...20)
            newSample.jitter_ms = Double.random(in: 1...20)
            newSample.packet_loss_pct = Double.random(in: 0...1) > 0.9 ? Double.random(in: 0...5) : 0
            newSample.download_bps_est = Double.random(in: 100_000_000...500_000_000)
            newSample.upload_bps_est = Double.random(in: 10_000_000...50_000_000)
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
        container = NSPersistentContainer(name: "SpeckitNetworkMonitor")
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
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
