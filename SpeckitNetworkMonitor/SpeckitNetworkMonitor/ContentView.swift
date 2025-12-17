//
//  ContentView.swift
//  SpeckitNetworkMonitor
//
//  Created by Maurice Roach on 13/12/2025.
//

import SwiftUI
import Charts // Import the Charts framework
import Combine

// Extension to calculate the average of a sequence of floating point numbers
extension Sequence where Element: FloatingPoint {
    func average() -> Element? {
        let elements = Array(self)
        guard !elements.isEmpty else { return nil }
        let sum = elements.reduce(0, +)
        return sum / Element(elements.count)
    }
}

struct ContentView: View {
    @StateObject private var xpcManager = XPCManager()

    @State private var startDate: Date = Calendar.current.date(byAdding: .hour, value: -1, to: Date())!
    @State private var endDate: Date = Date()
    @State private var selectedIntervalType: String = "5m"
    @State private var selectedMetricType: String = "latency"
    @State private var notificationsEnabled: Bool = false
        @State private var latencyThreshold: Double = 100.0
        @State private var packetLossThreshold: Double = 5.0
        @State private var consecutiveFailuresThreshold: Int = 3
    
        private let availableIntervalTypes = ["5m", "1h"]
        private let availableMetricTypes = ["latency", "jitter", "packetLoss", "download", "upload"]
    
        // Timer to fetch data every 5 seconds
        private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
        var body: some View {
            VStack(spacing: 20) {
                Text("Network Monitor")
                    .font(.largeTitle)
    
                VStack {
                    Text("Connection Status:")
                    Text(xpcManager.connectionStatus)
                        .foregroundColor(xpcManager.connectionStatus == "Connected" ? .green : .red)
                }
    
                if let sample = xpcManager.latestSample {
                    VStack {
                        Text("Live Latency")
                            .font(.headline)
                        Text(String(format: "%.2f ms", sample.latency))
                            .font(.system(size: 40, weight: .bold, design: .monospaced))
                    }
                } else {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                }
    
                Divider()
    
                // Time Range Selection
                VStack(alignment: .leading) {
                    Text("Historical Data Range:")
                        .font(.headline)
                    HStack {
                        DatePicker("From", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                        DatePicker("To", selection: $endDate, displayedComponents: [.date, .hourAndMinute])
                    }
    
                    Picker("Interval", selection: $selectedIntervalType) {
                        ForEach(availableIntervalTypes, id: \.self) {
                            type in
                            Text(type).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedIntervalType) { fetchHistoricalAggregatedData() }
    
                    Picker("Metric", selection: $selectedMetricType) {
                        ForEach(availableMetricTypes, id: \.self) {
                            type in
                            Text(type).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedMetricType) { fetchHistoricalAggregatedData() }
                }
                .padding(.horizontal)
    
                Text("Historical \(selectedMetricType.capitalized) (Last \(Int(endDate.timeIntervalSince(startDate)/60)) minutes)")
                    .font(.headline)
    
                // Chart to display historical aggregated data
                Chart {
                    ForEach(aggregatedSeriesForSelectedMetric()) { series in
                        ForEach(series.data, id: \.date) { sample in
                            LineMark(
                                x: .value("Time", sample.date),
                                y: .value(series.metric, sample.value)
                            )
                        }
                    }
    
                    if let averageValue = aggregatedSeriesForSelectedMetric().flatMap({ $0.data }).map({$0.value}).average() {
                        RuleMark(y: .value("Average", averageValue))
                            .foregroundStyle(.red)
                            .annotation(position: .topLeading) {
                                Text("Avg: \(averageValue, format: .number.precision(.fractionLength(2)))")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                    }
                }
                .chartYAxisLabel("\(selectedMetricType.capitalized) (\(metricUnit()))")
                .frame(height: 200)
    
                Divider()
    
                // Notification Settings
                VStack(alignment: .leading) {
                    Text("Notification Settings")
                        .font(.headline)
                    Toggle(isOn: $notificationsEnabled) {
                        Text("Enable Latency Notifications")
                    }
                    .onChange(of: notificationsEnabled) { updateNotificationSettings() }
    
                    HStack {
                        Text("Latency Threshold: \(latencyThreshold, format: .number.precision(.fractionLength(0))) ms")
                        Slider(value: $latencyThreshold, in: 50...500, step: 10) {
                            Text("Latency Threshold")
                        } minimumValueLabel: {
                            Text("50")
                        } maximumValueLabel: {
                            Text("500")
                        }
                        .onChange(of: latencyThreshold) { updateNotificationSettings() }
                    }
    
                    HStack {
                        Text("Packet Loss Threshold: \(packetLossThreshold, format: .number.precision(.fractionLength(1))) %")
                        Slider(value: $packetLossThreshold, in: 0...100, step: 1) {
                            Text("Packet Loss Threshold")
                        } minimumValueLabel: {
                            Text("0")
                        } maximumValueLabel: {
                            Text("100")
                        }
                                                                    .onChange(of: packetLossThreshold) { updateNotificationSettings() }                    }
    
                    HStack {
                        Text("Consecutive Failures Threshold: \(consecutiveFailuresThreshold)")
                        Stepper("Consecutive Failures", value: $consecutiveFailuresThreshold, in: 1...10)
                                                                    .onChange(of: consecutiveFailuresThreshold) { updateNotificationSettings() }                    }
                }
                .padding(.horizontal)
    
                Spacer()
            }
            .padding()
            .frame(minWidth: 400, minHeight: 700) // Increased height to accommodate more controls and charts
            .onAppear {
                // Connect to the XPC agent when the view appears
                xpcManager.connect()
                // Fetch initial historical aggregated data
                fetchHistoricalAggregatedData()
                // Send initial notification settings
                updateNotificationSettings()
            }
            .onReceive(timer) { _ in
                // Fetch the latest sample periodically
                xpcManager.fetchLatestSample()
                // Fetch updated historical aggregated data periodically
                fetchHistoricalAggregatedData()
            }
        }
    
        private func fetchHistoricalAggregatedData() {
            xpcManager.fetchAggregatedSamples(from: startDate, to: endDate, intervalType: selectedIntervalType, metricType: "latency")
            xpcManager.fetchAggregatedSamples(from: startDate, to: endDate, intervalType: selectedIntervalType, metricType: "jitter")
            xpcManager.fetchAggregatedSamples(from: startDate, to: endDate, intervalType: selectedIntervalType, metricType: "packetLoss")
            xpcManager.fetchAggregatedSamples(from: startDate, to: endDate, intervalType: selectedIntervalType, metricType: "download")
            xpcManager.fetchAggregatedSamples(from: startDate, to: endDate, intervalType: selectedIntervalType, metricType: "upload")
        }
    
        private func updateNotificationSettings() {
            let config = NotificationConfigurationDTO(isEnabled: notificationsEnabled, latencyThreshold: latencyThreshold, packetLossThreshold: packetLossThreshold, consecutiveFailuresThreshold: consecutiveFailuresThreshold)
            xpcManager.updateNotificationConfiguration(configuration: config)
        }
    
    private func aggregatedSeriesForSelectedMetric() -> [AggregatedSeriesDTO] {
        switch selectedMetricType {
        case "latency":
            return xpcManager.aggregatedLatencySeries
        case "jitter":
            return xpcManager.aggregatedJitterSeries
        case "packetLoss":
            return xpcManager.aggregatedPacketLossSeries
        case "download":
            return xpcManager.aggregatedDownloadSeries
        case "upload":
            return xpcManager.aggregatedUploadSeries
        default:
            return []
        }
    }

    private func metricUnit() -> String {
        switch selectedMetricType {
        case "latency", "jitter":
            return "ms"
        case "packetLoss":
            return "%"
        case "download", "upload":
            return "Mbps"
        default:
            return ""
        }
    }
}
