//
//  LatencyChart.swift
//  NetworkReporter
//
//  Created by Maurice Roach on 22/12/2025.
//

import SwiftUI
import NetworkReporterShared // FIX: For ConnectivityStatus enum
import Charts // Requires macOS 13+ or iOS 16+

struct LatencyChart: View {
    let records: [NetworkPerformanceRecord]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Latency Over Time")
                .font(.headline)
            
            chartView // Use extracted chart view
            .frame(height: 200)
            .accessibilityLabel("Line chart showing network latency in milliseconds over time. A dashed red line indicates the high latency threshold of 200 milliseconds.")
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
                AxisValueLabel("ms")
            }
        }
        .chartYScale(domain: 0...(records.map { $0.latency }.max() ?? 100) + 50) // Adjust Y-axis scale dynamically
    }

    @ChartContentBuilder
    private var chartContent: some ChartContent {
        ForEach(records) { record in
            LineMark(
                x: .value("Time", record.timestamp_),
                y: .value("Latency (ms)", record.latency)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(connectivityStatusColor(for: record.connectivityStatus_.description))
            .symbol(
                record.connectivityStatus_ == .connected ? .circle :
                (record.connectivityStatus_ == .degraded ? .triangle : .square)
            )
            
            // Add point marks for individual data points, especially for degraded status
            PointMark(
                x: .value("Time", record.timestamp_),
                y: .value("Latency (ms)", record.latency)
            )
            .foregroundStyle(connectivityStatusColor(for: record.connectivityStatus_.description))
            .symbol(
                record.connectivityStatus_ == .connected ? .circle :
                (record.connectivityStatus_ == .degraded ? .triangle : .square)
            )
            .opacity(records.count < 50 ? 1 : 0) // Show points only if not too many records
        }
        // Add a reference line for high latency threshold
        RuleMark(y: .value("High Latency Threshold", 200.0))
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
            .foregroundStyle(.red)
            .annotation(position: .overlay, alignment: .trailing) {
                Text("High Latency (200ms)")
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
    //     case ConnectivityStatus.degraded.description: return .triangle
    //     case ConnectivityStatus.disconnected.description: return .square
    //     default: return .circle
    //     }
    // }

    @ViewBuilder
    private func axisValueLabelContent(for value: AxisValue) -> some View {
        if let intValue = value.as(Int.self) { // For ConnectivityStatus
            switch intValue {
            case 0: Text("Connected")
            case 1: Text("Degraded")
            case 2: Text("Disconnected")
            default: Text("")
            }
        } else if let doubleValue = value.as(Double.self) { // For percentage/ms if needed
            Text(doubleValue, format: .number.precision(.fractionLength(0)))
        } else {
            Text("")
        }
    }
}

struct LatencyChart_Previews: PreviewProvider {
    static var previews: some View {
        // Create some dummy records for preview
        let context = PersistenceController.preview.container.viewContext
        var dummyRecords: [NetworkPerformanceRecord] = []
        for i in 0..<20 {
            let record = NetworkPerformanceRecord(context: context)
            record.id = UUID()
            record.timestamp = Date().addingTimeInterval(Double(i * 60 * 10)) // Every 10 minutes
            record.latency = Double.random(in: 20...250) // Include some high latency
            record.packetLoss = Double.random(in: 0...0.02)
            record.connectivityStatus = Int16.random(in: 0...2)
            if i == 5 { record.latency = 210 } // Force a high latency
            if i == 10 { record.connectivityStatus = ConnectivityStatus.disconnected.rawValue } // Force disconnected
            dummyRecords.append(record)
        }
        
        return LatencyChart(records: dummyRecords)
            .padding()
            .environment(\.managedObjectContext, context)
    }
}