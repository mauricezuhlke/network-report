//
//  ContentView.swift
//  NetworkReporter
//
//  Created by Maurice Roach on 22/12/2025.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var xpcClient: XPCClient // Injected from NetworkReporterApp

    var body: some View {
        NavigationView { // Added NavigationView for potential future navigation
            VStack {
                RealTimeNetworkView(recentRecords: xpcClient.recentPerformanceRecords) // Pass recent records directly
                    .padding(.bottom)

                // UI Feedback for network sampling status
                HStack {
                    Text("Service Status: ")
                        .font(.subheadline)
                    Text(xpcClient.isServiceConnected ? "Connected" : "Disconnected")
                        .font(.subheadline)
                        .foregroundColor(xpcClient.isServiceConnected ? .green : .red)
                }
                
                // Display error messages from XPCClient
                if let error = xpcClient.currentError {
                    Text("Error: \(error.localizedDescription)")
                        .foregroundColor(.red)
                        .font(.subheadline)
                        .padding(.top, 5)
                }

                if let latestRecord = xpcClient.latestPerformanceRecord { // Use XPCClient's latest record
                    Text("Last Sample: \(latestRecord.timestamp ?? Date(), formatter: Self.dateFormatter)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                } else if xpcClient.isServiceConnected {
                    Text("Waiting for first sample...")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Network Monitor")
        }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter
    }()
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(XPCClient(persistenceController: PersistenceController.preview)) // Provide XPCClient for preview
    }
}
