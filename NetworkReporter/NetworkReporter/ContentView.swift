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
    @StateObject private var viewModel = ContentViewModel() // Owns view-specific state

    var body: some View {
        NavigationView { // Added NavigationView for potential future navigation
            VStack {
                RealTimeNetworkView()
                    .padding(.bottom)

                // UI Feedback for network sampling status
                HStack {
                    Text("Service Status: ")
                        .font(.subheadline)
                    Text(xpcClient.isServiceConnected ? "Connected" : "Disconnected")
                        .font(.subheadline)
                        .foregroundColor(xpcClient.isServiceConnected ? .green : .red)
                }
                if let latestRecord = xpcClient.latestPerformanceRecord {
                    Text("Last Sample: \(latestRecord.timestamp ?? Date(), formatter: Self.dateFormatter)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                } else if xpcClient.isServiceConnected {
                    Text("Waiting for first sample...")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                // Display error messages from ViewModel
                if let errorMessage = viewModel.errorMessage {
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.red)
                }
                
                Spacer()
            }
            .padding()
            .onAppear {
                // Set up the observer for XPCClient's latest data
                viewModel.observeXPCClient(xpcClient)
            }
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
