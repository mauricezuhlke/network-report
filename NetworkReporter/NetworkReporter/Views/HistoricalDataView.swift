//
//  HistoricalDataView.swift
//  NetworkReporter
//
//  Created by Maurice Roach on 22/12/2025.
//

import SwiftUI
import CoreData

struct HistoricalDataView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var xpcClient: XPCClient // To potentially trigger refresh or monitoring
    @StateObject private var viewModel = NetworkChartViewModel(context: PersistenceController.shared.container.viewContext)

    var body: some View {
        VStack {
            Text("Historical Network Performance")
                .font(.headline)
                .padding(.bottom)
            
            Picker("Time Range", selection: $viewModel.selectedTimeRange) {
                ForEach(TimeRange.allCases) { range in
                    Text(range.description).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .onChange(of: viewModel.selectedTimeRange) { _, newRange in // FIX: Use two-parameter onChange syntax
                viewModel.fetchHistoricalRecords()
            }
            
            if viewModel.historicalRecords.isEmpty {
                Text("No historical data available for selected range.")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        LatencyChart(records: viewModel.historicalRecords)
                        PacketLossChart(records: viewModel.historicalRecords)
                        ConnectivityChart(records: viewModel.historicalRecords)
                        SpeedChart(records: viewModel.historicalRecords)
                    }
                    .padding()
                }
            }
            Spacer()
        }
        .onAppear {
            viewModel.fetchHistoricalRecords()
        }
        .navigationTitle("History")
    }

    private static let itemFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter
    }()
}

struct HistoricalDataView_Previews: PreviewProvider {
    static var previews: some View {
        HistoricalDataView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(XPCClient(persistenceController: PersistenceController.preview))
    }
}