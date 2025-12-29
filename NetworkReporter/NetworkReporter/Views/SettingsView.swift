//
//  SettingsView.swift
//  NetworkReporter
//
//  Created by Maurice Roach on 2025-12-29.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("monitoringInterval") private var monitoringInterval: Double = 5.0 // Default to 5 seconds

    var body: some View {
        Form {
            Text("Network Reporter Settings")
                .font(.title2)
                .padding(.bottom, 5)
            
            Section(header: Text("Monitoring").padding(.bottom, 5)) {
                Slider(value: $monitoringInterval, in: 1...60, step: 1) {
                    Text("Monitoring Interval (\(Int(monitoringInterval)) seconds)")
                } minimumValueLabel: {
                    Text("1s")
                } maximumValueLabel: {
                    Text("60s")
                }
                .controlSize(.large)
            }
            
            Section(header: Text("Data Persistence").padding(.bottom, 5)) {
                // Future settings related to data retention, etc.
                Text("Data Retention: (Coming Soon)")
            }
            
            Section(header: Text("About").padding(.bottom, 5)) {
                Text("Version: 1.0.0") // Placeholder
                Text("© 2025 Maurice Roach")
            }
        }
        .padding()
        .frame(minWidth: 400, minHeight: 300)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
