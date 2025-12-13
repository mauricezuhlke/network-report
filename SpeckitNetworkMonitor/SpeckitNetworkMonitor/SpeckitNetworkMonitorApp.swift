//
//  SpeckitNetworkMonitorApp.swift
//  SpeckitNetworkMonitor
//
//  Created by Maurice Roach on 13/12/2025.
//

import SwiftUI
import CoreData

@main
struct SpeckitNetworkMonitorApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
