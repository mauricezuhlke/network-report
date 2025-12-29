//
//  RealTimeNetworkView.swift
//  NetworkReporter
//
//  Created by Maurice Roach on 22/12/2025.
//

import SwiftUI
import NetworkReporterShared // FIX: For ConnectivityStatus.description

struct RealTimeNetworkView: View {
    var realTimeRecord: NetworkPerformanceRecord? // Receive record directly

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Real-Time Network Status")
                .font(.headline)
            
            if let record = realTimeRecord {
                MetricRow(label: "Status", value: record.connectivityStatus_.description)
                MetricRow(label: "Latency", value: String(format: "%.0f ms", record.latency))
                MetricRow(label: "Packet Loss", value: String(format: "%.2f%%", record.packetLoss * 100))
                MetricRow(label: "Upload Speed", value: String(format: "%.1f Mbps", record.uploadSpeed))
                MetricRow(label: "Download Speed", value: String(format: "%.1f Mbps", record.downloadSpeed))
                Text("Last updated: \(record.timestamp ?? Date(), formatter: itemFormatter)") // Use record.timestamp directly
                    .font(.caption)
                    .foregroundColor(.gray)
            } else {
                Text("Connecting to service and collecting data...")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private let itemFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter
    }()
}

struct MetricRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label + ":")
                .fontWeight(.medium)
            Spacer()
            Text(value)
        }
    }
}

struct RealTimeNetworkView_Previews: PreviewProvider {
    static var previews: some View {
        RealTimeNetworkView(realTimeRecord: nil) // Provide a nil record for initial preview state
    }
}