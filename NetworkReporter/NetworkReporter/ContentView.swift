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
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(XPCClient(persistenceController: PersistenceController.preview)) // Provide XPCClient for preview
    }
}