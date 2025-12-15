//
//  SpeckitNetworkMonitorApp.swift
//  SpeckitNetworkMonitor
//
//  Created by Maurice Roach on 13/12/2025.
//

import SwiftUI
import CoreData
import AppKit
import Combine
import UserNotifications // Added
import OSLog // Added

fileprivate let logger = Logger(subsystem: "com.speckit.SpeckitNetworkMonitor", category: "App") // Added

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    var statusItem: NSStatusItem?
    var popover = NSPopover()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "network", accessibilityDescription: "Network Monitor")
            button.action = #selector(togglePopover(_:))
        }

        popover.contentViewController = NSHostingController(rootView: ContentView())
        popover.behavior = .transient // Dismisses when user clicks outside
        
        // Request notification authorization on app launch
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                logger.log("Notification authorization granted for main app.")
            } else if let error = error {
                logger.error("Notification authorization failed for main app: \(error.localizedDescription)")
            }
        }
    }
    
    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = statusItem?.button {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }
}


@main
struct SpeckitNetworkMonitorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
    }
}
