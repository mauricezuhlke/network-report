//
//  ContentViewModel.swift
//  NetworkReporter
//
//  Created by Maurice Roach on 22/12/2025.
//

import Foundation
import Combine

class ContentViewModel: ObservableObject {
    @Published var timestamp: String?
    @Published var errorMessage: String?
    
    private let xpcClient = XPCClient()
    
    @MainActor
    func fetchTimestamp() async {
        errorMessage = nil // Clear previous errors
        timestamp = nil // Clear previous timestamp

        do {
            let fetchedTimestamp = try await xpcClient.getTimestamp()
            timestamp = fetchedTimestamp
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
