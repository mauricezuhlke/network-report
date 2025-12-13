//
//  ContentView.swift
//  SpeckitNetworkMonitor
//
//  Created by Maurice Roach on 13/12/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var xpcManager = XPCManager()

    // Timer to fetch data every 5 seconds
    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 20) {
            Text("Speckit Network Monitor")
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
        }
        .padding()
        .frame(minWidth: 400, minHeight: 300)
        .onAppear {
            // Connect to the XPC agent when the view appears
            xpcManager.connect()
        }
        .onReceive(timer) { _ in
            // Fetch the latest sample periodically
            xpcManager.fetchLatestSample()
        }
    }
}

#Preview {
    ContentView()
}
