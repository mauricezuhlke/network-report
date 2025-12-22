//
//  ContentView.swift
//  NetworkReporter
//
//  Created by Maurice Roach on 22/12/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var timestamp: Date?
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            if let timestamp = timestamp {
                Text("Timestamp from service: \(timestamp, formatter: itemFormatter)")
            } else if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
            } else {
                Text("No response yet")
            }
        }
        .padding()

        Button("Get Timestamp") {
            callXPCService()
        }
    }

    private func callXPCService() {
        let connection = NSXPCConnection(serviceName: "maro.NetworkReporterService")
        connection.remoteObjectInterface = NSXPCInterface(with: NetworkReporterServiceProtocol.self)
        connection.resume()

        if let proxy = connection.remoteObjectProxy as? NetworkReporterServiceProtocol {
            proxy.getTimestamp { response in
                DispatchQueue.main.async {
                    self.timestamp = response
                    self.errorMessage = nil
                }
                connection.invalidate()
            }
        } else {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to create proxy"
                self.timestamp = nil
            }
            connection.invalidate()
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .long
    formatter.timeStyle = .long
    return formatter
}()

#Preview {
    ContentView()
}
