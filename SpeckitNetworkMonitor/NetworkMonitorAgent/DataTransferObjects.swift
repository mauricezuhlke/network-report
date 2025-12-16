import Foundation

public struct NetworkSampleDTO: Codable, Identifiable {
    public var id: Date { timestamp }
    public let timestamp: Date
    public let latency: TimeInterval
    public let packetLoss: Double
    public let connectivity: Bool
}

public struct AggregatedSeriesDTO: Codable, Identifiable {
    public var id = UUID()
    public let metric: String // e.g., "Latency", "Packet Loss"
    public let data: [GraphPoint]
}

public struct GraphPoint: Codable {
    public let date: Date
    public let value: Double
}


public struct NotificationConfigurationDTO: Codable {
    public var isEnabled: Bool
    public var latencyThreshold: Double
    public var packetLossThreshold: Double
    public var consecutiveFailuresThreshold: Int
}
