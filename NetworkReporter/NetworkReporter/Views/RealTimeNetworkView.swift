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

            

            Divider()

            

            Text("Recent Trends")

                .font(.title2)

                .padding(.top, 5)

            

            // Charts will go here

            ConnectivityChart(records: recentRecords)

                .frame(height: 100)

            LatencyChart(records: recentRecords)

                .frame(height: 100)

            PacketLossChart(records: recentRecords)

                .frame(height: 100)

            SpeedChart(records: recentRecords)

                .frame(height: 100)



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

        .frame(maxWidth: .infinity)

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

            }(),

            // Sample record 2

            {

                let record = NetworkPerformanceRecord(context: PersistenceController.preview.container.viewContext)

                record.timestamp = Date().addingTimeInterval(-20)

                record.latency = 60

                record.packetLoss = 0.0

                record.connectivityStatus = ConnectivityStatus.connected.rawValue

                record.uploadSpeed = 25

                record.downloadSpeed = 120

                return record

            }(),

            // Sample record 3

            {

                let record = NetworkPerformanceRecord(context: PersistenceController.preview.container.viewContext)

                record.timestamp = Date().addingTimeInterval(-10)

                record.latency = 75

                record.packetLoss = 0.02

                record.connectivityStatus = ConnectivityStatus.degraded.rawValue

                record.uploadSpeed = 15

                record.downloadSpeed = 80

                return record

            }()

        ]

        

        RealTimeNetworkView(recentRecords: sampleRecords)

            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)

    }

}
