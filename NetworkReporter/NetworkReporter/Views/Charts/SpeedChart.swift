//
//  SpeedChart.swift
//  NetworkReporter
//
//  Created by Maurice Roach on 22/12/2025.
//

import SwiftUI
import NetworkReporterShared // FIX: For ConnectivityStatus enum
import Charts // Requires macOS 13+ or iOS 16+

struct SpeedChart: View {
    let records: [NetworkPerformanceRecord]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Upload/Download Speed Over Time")
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
                AxisValueLabel("Mbps")
            }
        }
        .chartYScale(domain: 0...(records.map { max($0.uploadSpeed, $0.downloadSpeed) }.max() ?? 50) + 50)
    }

    @ChartContentBuilder
    private var chartContent: some ChartContent {
        ForEach(records) { record in
            LineMark(
                x: .value("Time", record.timestamp_),
                y: .value("Upload Speed (Mbps)", record.uploadSpeed)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(connectivityStatusColor(for: record.connectivityStatus_.description))
            .symbol(
                record.connectivityStatus_ == .connected ? .circle :
                (record.connectivityStatus_ == .degraded ? .triangle : .square)
            )
            
            LineMark(
                x: .value("Time", record.timestamp_),
                y: .value("Download Speed (Mbps)", record.downloadSpeed)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(connectivityStatusColor(for: record.connectivityStatus_.description))
            .symbol(
                record.connectivityStatus_ == .connected ? .circle :
                (record.connectivityStatus_ == .degraded ? .triangle : .square)
            )
            
            // Add PointMarks with specific colors for degraded states
            if record.connectivityStatus_ == .degraded {
                PointMark(
                    x: .value("Time", record.timestamp_),
                    y: .value("Upload Speed (Mbps)", record.uploadSpeed)
                )
                .foregroundStyle(.orange)
                .symbol(.triangle)
                
                PointMark(
                    x: .value("Time", record.timestamp_),
                    y: .value("Download Speed (Mbps)", record.downloadSpeed)
                )
                .foregroundStyle(.orange)
                .symbol(.triangle)
            }
            if record.connectivityStatus_ == .disconnected {
                PointMark(
                    x: .value("Time", record.timestamp_),
                    y: .value("Upload Speed (Mbps)", record.uploadSpeed)
                )
                .foregroundStyle(.red)
                .symbol(.square)
                
                PointMark(
                    x: .value("Time", record.timestamp_),
                    y: .value("Download Speed (Mbps)", record.downloadSpeed)
                )
                .foregroundStyle(.red)
                .symbol(.square)
            }
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

    // This helper function is now unused for symbols, but might be useful for other things.
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

struct SpeedChart_Previews: PreviewProvider {
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
            record.connectivityStatus = Int16.random(in: 0...2)
            if i == 5 { record.connectivityStatus = ConnectivityStatus.degraded.rawValue } // Force degraded
            if i == 10 { record.connectivityStatus = ConnectivityStatus.disconnected.rawValue } // Force disconnected
            dummyRecords.append(record)
        }
        
        return SpeedChart(records: dummyRecords)
            .padding()
            .environment(\.managedObjectContext, context)
    }
}