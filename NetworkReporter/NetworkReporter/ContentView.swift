//
//  ContentView.swift
//  NetworkReporter
//
//  Created by Maurice Roach on 22/12/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()

    var body: some View {
        VStack {
            if let timestamp = viewModel.timestamp {
                Text("Timestamp from service: \(timestamp)")
            } else if let errorMessage = viewModel.errorMessage {
                Text("Error: \(errorMessage)")
            } else {
                Text("No response yet")
            }
        }
        .padding()

        Button("Get Timestamp") {
            Task {
                await viewModel.fetchTimestamp()
            }
        }
    }
}

#Preview {
    ContentView()
}
