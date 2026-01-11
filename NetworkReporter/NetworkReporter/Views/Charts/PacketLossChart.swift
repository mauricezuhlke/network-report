//
//  PacketLossChart.swift
//  NetworkReporter
//
//  Created by Maurice Roach on 22/12/2025.
//

import SwiftUI
import NetworkReporterShared // FIX: For ConnectivityStatus enum
import Charts // Requires macOS 13+ or iOS 16+

struct PacketLossChart: View {
    let records: [NetworkPerformanceRecord]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Packet Loss Over Time")
                .font(.headline)
            
            chartView // Use extracted chart view
            .frame(height: 200)
            .accessibilityLabel("Line chart showing network packet loss as a percentage over time. A dashed red line indicates the high packet loss threshold of 5%.")
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
                AxisValueLabel("%")
            }
        }
        .chartYScale(domain: 0...100) // Packet loss is 0-100%
    }
    
    @ChartContentBuilder
    private var chartContent: some ChartContent {
        ForEach(records) { record in
            LineMark(
                x: .value("Time", record.timestamp_),
                y: .value("Packet Loss (%)", record.packetLoss * 100)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(connectivityStatusColor(for: record.connectivityStatus_.description))
            .symbol(
                record.connectivityStatus_ == .connected ? .circle :
                (record.connectivityStatus_ == .degraded ? .triangle : .square)
            )
            
            // Add point marks for individual data points
            PointMark(
                x: .value("Time", record.timestamp_),
                y: .value("Packet Loss (%)", record.packetLoss * 100)
            )
            .foregroundStyle(connectivityStatusColor(for: record.connectivityStatus_.description))
            .symbol(
                record.connectivityStatus_ == .connected ? .circle :
                (record.connectivityStatus_ == .degraded ? .triangle : .square)
            )
            .opacity(records.count < 50 ? 1 : 0) // Show points only if not too many records
        }
        // Add a reference line for high packet loss threshold
        RuleMark(y: .value("High Packet Loss Threshold", 5.0))
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
            .foregroundStyle(.red)
            .annotation(position: .overlay, alignment: .trailing) {
                Text("High Packet Loss (5%)")
                    .font(.caption)
                    .foregroundColor(.red)
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

    // Removed connectivityStatusSymbol function
    // private func connectivityStatusSymbol(for status: String) -> any ChartSymbolShape {
    //     switch status {
    //     case ConnectivityStatus.connected.description: return .circle
    //     // case ConnectivityStatus.degraded.description: return .triangle // Redundant
    //     // case ConnectivityStatus.disconnected.description: return .square // Redundant
    //     default: return .circle
    //     }
    // }

    @ViewBuilder
    private func axisValueLabelContent(for value: AxisValue) -> some View {
        if let intValue = value.as(Int.self) { // Assuming intValue is 0, 1, 2 for ConnectivityStatus
            switch intValue {
            case 0: Text("Connected")
            case 1: Text("Degraded")
            case 2: Text("Disconnected")
            default: Text("")
            }
        } else if let doubleValue = value.as(Double.self) { // For percentage
            Text(doubleValue, format: .percent.precision(.fractionLength(0)))
        } else {
            Text("")
        }
    }
}

struct PacketLossChart_Previews: PreviewProvider {
    static var previews: some View {
        // Create some dummy records for preview
        let context = PersistenceController.preview.container.viewContext
        var dummyRecords: [NetworkPerformanceRecord] = []
        for i in 0..<20 {
            let record = NetworkPerformanceRecord(context: context)
            record.id = UUID()
            record.timestamp = Date().addingTimeInterval(Double(i * 60 * 10)) // Every 10 minutes
            record.latency = Double.random(in: 20...150)
            record.packetLoss = Double.random(in: 0...0.1) // Max 10% loss for preview
            record.connectivityStatus = Int16.random(in: 0...2)
            if i == 5 { record.packetLoss = 0.06 } // Force a high packet loss
            if i == 10 { record.connectivityStatus = ConnectivityStatus.disconnected.rawValue } // Force disconnected
            dummyRecords.append(record)
        }
        
        return PacketLossChart(records: dummyRecords)
            .padding()
            .environment(\.managedObjectContext, context)
    }
}
