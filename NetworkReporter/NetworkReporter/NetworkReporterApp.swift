//
//  NetworkReporterApp.swift
//  NetworkReporter
//
//  Created by Maurice Roach on 22/12/2025.
//

import SwiftUI
import CoreData

@main
struct NetworkReporterApp: App {
    @Environment(\.scenePhase) private var scenePhase // For app lifecycle events
    
    let persistenceController = PersistenceController.shared
    @StateObject private var xpcClient = XPCClient(persistenceController: PersistenceController.shared) // Initialize XPCClient directly

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(xpcClient) // Make XPCClient available to views
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in // FIX: Use two-parameter onChange syntax
            switch newPhase {
            case .active:
                NSLog("App became active. Starting monitoring.")
                Task {
                    do {
                        try await xpcClient.startMonitoring()
                    } catch {
                        NSLog("Error starting monitoring: \(error.localizedDescription)")
                    }
                }
            case .inactive:
                // For macOS, 'inactive' means it's still running but not frontmost/focused.
                // We might choose to continue monitoring or pause. For now, pause.
                NSLog("App became inactive. Pausing monitoring.")
                Task {
                    do {
                        try await xpcClient.stopMonitoring()
                    } catch {
                        NSLog("Error pausing monitoring: \(error.localizedDescription)")
                    }
                }
            case .background:
                // For a desktop app, going to background might mean stopping monitoring
                // or continuing in a low-power mode. For now, stop monitoring.
                NSLog("App went to background. Stopping monitoring.")
                Task {
                    do {
                        try await xpcClient.stopMonitoring()
                    } catch {
                        NSLog("Error stopping monitoring: \(error.localizedDescription)")
                    }
                }
            @unknown default:
                NSLog("Unknown scene phase.")
            }
        }
    }
}