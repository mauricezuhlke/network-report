//
//  ConnectivityChart.swift
//  NetworkReporter
//
//  Created by Maurice Roach on 22/12/2025.
//

import SwiftUI
import NetworkReporterShared // FIX: For ConnectivityStatus enum
import Charts // Requires macOS 13+ or iOS 16+

struct ConnectivityChart: View {
    let records: [NetworkPerformanceRecord]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Connectivity Status Over Time")
                .font(.headline)
            
            chartView // Use extracted chart view
            .frame(height: 200)
        }
    }
    
    // MARK: - Private Helpers
    private var chartView: some View {
        Chart { chartContent }
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(date, format: .dateTime.hour().minute())
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    axisValueLabelContent(for: value)
                }
            }
        }
    }

    @ChartContentBuilder
    private var chartContent: some ChartContent {
        ForEach(records) { record in
            BarMark(
                x: .value("Time", record.timestamp_),
                yStart: .value("Status", 0),
                yEnd: .value("Status", 1) // Using 0 and 1 to represent status height
            )
            .foregroundStyle(connectivityStatusColor(for: record.connectivityStatus_.description)) // Apply color directly
            .position(by: .value("Status", record.connectivityStatus_.description))
        }
    }

    private func connectivityStatusColor(for status: String) -> Color {
        switch status {
        case ConnectivityStatus.connected.description: return .green
        case ConnectivityStatus.degraded.description: return .orange
        case ConnectivityStatus.disconnected.description: return .red
        default: return .gray
        }
    }
 
    @ViewBuilder
    private func axisValueLabelContent(for value: AxisValue) -> some View { // Renamed helper
        if let intValue = value.as(Int.self) {
            switch intValue {
            case 0: Text("Connected")
            case 1: Text("Degraded")
            case 2: Text("Disconnected")
            default: Text("")
            }
        }
    }
}

struct ConnectivityChart_Previews: PreviewProvider {
    static var previews: some View {
        // Create some dummy records for preview
        let context = PersistenceController.preview.container.viewContext
        var dummyRecords: [NetworkPerformanceRecord] = []
        for i in 0..<20 {
            let record = NetworkPerformanceRecord(context: context)
            record.id = UUID()
            record.timestamp = Date().addingTimeInterval(Double(i * 60 * 10)) // Every 10 minutes
            record.latency = Double.random(in: 20...150)
            record.packetLoss = Double.random(in: 0...0.1)
            record.connectivityStatus = Int16.random(in: 0...2) // Vary status
            record.uploadSpeed = Double.random(in: 10...50)
            record.downloadSpeed = Double.random(in: 50...200)
            dummyRecords.append(record)
        }
        
        return ConnectivityChart(records: dummyRecords)
            .padding()
            .environment(\.managedObjectContext, context)
    }
}
