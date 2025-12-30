//
//  RealTimeNetworkView.swift
//  NetworkReporter
//
//  Created by Maurice Roach on 22/12/2025.
//

import SwiftUI
import NetworkReporterShared // FIX: For ConnectivityStatus.description

struct RealTimeNetworkView: View {
    var recentRecords: [NetworkPerformanceRecord] // Receive an array of records

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Real-Time Network Status")
                .font(.title2)
                .padding(.bottom, 5)
            
            if let record = recentRecords.last { // Display latest record for real-time metrics
                HStack {
                    Text("Status:")
                        .fontWeight(.medium)
                    Spacer()
                    Text(record.connectivityStatus_.description)
                        .foregroundColor(connectivityStatusColor(for: record.connectivityStatus_.description))
                }
                .frame(maxWidth: .infinity)
                
                Text("Last updated: \(record.timestamp ?? Date(), formatter: itemFormatter)") // Use record.timestamp directly
                    .font(.caption)
                    .foregroundColor(.gray)
            } else {
                Text("Connecting to service and collecting data...")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(10)
        .shadow(radius: 5)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private let itemFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter
    }()
    
    private func connectivityStatusColor(for status: String) -> Color {
        switch status {
        case ConnectivityStatus.connected.description: return .green
        case ConnectivityStatus.degraded.description: return .orange
        case ConnectivityStatus.disconnected.description: return .red
        default: return .gray
        }
    }
}

struct RealTimeNetworkView_Previews: PreviewProvider {
    static var previews: some View {
        // Create some sample data for the preview
        let sampleRecords: [NetworkPerformanceRecord] = [
            // Sample record 1
            {
                let record = NetworkPerformanceRecord(context: PersistenceController.preview.container.viewContext)
                record.timestamp = Date().addingTimeInterval(-30)
                record.latency = 50
                record.packetLoss = 0.01
                record.connectivityStatus = ConnectivityStatus.connected.rawValue
                record.uploadSpeed = 20
                record.downloadSpeed = 100
                return record
            }()
        ]
        
        RealTimeNetworkView(recentRecords: sampleRecords)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
