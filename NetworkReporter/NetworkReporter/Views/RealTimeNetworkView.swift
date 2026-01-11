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
                VStack(spacing: 8) {
                    HStack {
                        Text("Status:")
                            .fontWeight(.medium)
                        Spacer()
                        Text(record.connectivityStatus_.description)
                            .foregroundColor(connectivityStatusColor(for: record.connectivityStatus_.description))
                    }
                    
                    HStack {
                        Text("Latency:")
                            .fontWeight(.medium)
                        Spacer()
                        Text(String(format: "%.2f ms", record.latency))
                    }
                    
                    HStack {
                        Text("Packet Loss:")
                            .fontWeight(.medium)
                        Spacer()
                        Text(String(format: "%.1f %%", record.packetLoss * 100))
                    }

                    HStack {
                        Text("Download Speed:")
                            .fontWeight(.medium)
                        Spacer()
                        Text(String(format: "%.2f Mbps", record.downloadSpeed))
                    }

                    HStack {
                        Text("Upload Speed:")
                            .fontWeight(.medium)
                        Spacer()
                        Text(String(format: "%.2f Mbps", record.uploadSpeed))
                    }
                }
                
                Text("Last updated: \(record.timestamp ?? Date(), formatter: itemFormatter)") // Use record.timestamp directly
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.top, 5)

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
