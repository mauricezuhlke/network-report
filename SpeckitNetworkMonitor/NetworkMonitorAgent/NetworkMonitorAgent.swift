//
//  NetworkMonitorAgent.swift
//  NetworkMonitorAgent
//
//  Created by Maurice Roach on 13/12/2025.
//

import Foundation
import OSLog
import Network
import CoreData
import SystemConfiguration
import AppKit
import UserNotifications

extension Array where Element == Double {
    func average() -> Double? {
        guard !self.isEmpty else { return nil }
        return self.reduce(0, +) / Double(self.count)
    }
}

fileprivate let logger = Logger(subsystem: "com.speckit.NetworkMonitorAgent", category: "Agent")

// MARK: - Core Data Persistence
struct PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        let appGroupIdentifier = "group.com.speckit.networkmonitor"
        
        container = NSPersistentContainer(name: "SpeckitNetworkMonitor")
        
        var storeURL: URL?
        if inMemory {
            storeURL = URL(fileURLWithPath: "/dev/null")
            logger.log("PersistenceController: Using in-memory store.")
        } else {
            if let fileContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
                storeURL = fileContainer.appendingPathComponent("SpeckitNetworkMonitor.sqlite")
                logger.log("PersistenceController: Using App Group shared container at \(storeURL!.path)")
            } else {
                logger.error("Failed to get container URL for App Group: \(appGroupIdentifier). Falling back to temporary directory.")
                storeURL = FileManager.default.temporaryDirectory.appendingPathComponent("SpeckitNetworkMonitor.sqlite")
            }
        }
        
        let description = NSPersistentStoreDescription(url: storeURL!)
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                logger.error("Unresolved error loading persistent store: \(error), \(error.userInfo)")
                // Depending on criticality, you might try to recover or inform the user.
                // For an agent, we log and let it continue.
            } else {
                logger.log("Successfully loaded persistent store: \(storeDescription.url?.lastPathComponent ?? "in-memory")")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    func newBackgroundTask() -> NSManagedObjectContext {
        return container.newBackgroundContext()
    }
}

// MARK: - Core Data Managed Object
@objc(NetworkSample)
public class NetworkSample: NSManagedObject {
    @NSManaged public var timestamp: Date
    @NSManaged public var latency_avg: Double
    @NSManaged public var latency_min: Double
    @NSManaged public var latency_max: Double
    @NSManaged public var jitter_ms: Double
    @NSManaged public var packet_loss_pct: Double
    @NSManaged public var upload_bps_est: Double
    @NSManaged public var download_bps_est: Double
}

@objc(AggregatedSeries)
public class AggregatedSeries: NSManagedObject {
    @NSManaged public var timestampStartUTC: Date
    @NSManaged public var timestampEndUTC: Date
    @NSManaged public var intervalType: String
    @NSManaged public var metricType: String
    @NSManaged public var valueAvg: Double
    @NSManaged public var valueMin: Double
    @NSManaged public var valueMax: Double
    @NSManaged public var interfaceID: String?
}


// MARK: - Measurement Classes


class TCPConnector {
    
    /// Measures the time to establish a TCP connection using Berkeley Sockets.
    func connect(host: String, port: UInt16, completion: @escaping (TimeInterval?) -> Void) {
        var hints = addrinfo()
        hints.ai_family = AF_INET // Specify IPv4, can be AF_UNSPEC for both
        hints.ai_socktype = SOCK_STREAM
        
        var res: UnsafeMutablePointer<addrinfo>?
        
        // Resolve host and port
        let ret = getaddrinfo(host, String(port), &hints, &res)
        if ret != 0 {
            logger.error("TCPConnector: getaddrinfo failed for host \(host): \(String(cString: gai_strerror(ret)))")
            completion(nil)
            return
        }
        
        guard let info = res else {
            completion(nil)
            return
        }
        
        defer {
            freeaddrinfo(info)
        }
        
        // Create a socket
        let sock = socket(info.pointee.ai_family, info.pointee.ai_socktype, info.pointee.ai_protocol)
        if sock < 0 {
            logger.error("TCPConnector: failed to create socket.")
            completion(nil)
            return
        }
        
        defer {
            close(sock)
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Connect to the server
        let connectResult = Darwin.connect(sock, info.pointee.ai_addr, info.pointee.ai_addrlen)
        
        let endTime = CFAbsoluteTimeGetCurrent()
        
        if connectResult < 0 {
            logger.error("TCPConnector: failed to connect to host \(host).")
            completion(nil)
            return
        }
        
        let connectionTime = (endTime - startTime) * 1000 // in ms
        completion(connectionTime)
    }
}
class JitterCalculator {
    
    /// Calculates the standard deviation of a sample of latency values.
    func calculate(samples: [Double]) -> Double? {
        guard samples.count > 1 else { return nil }
        
        let mean = samples.reduce(0, +) / Double(samples.count)
        let sumOfSquaredDifferences = samples.map { pow($0 - mean, 2.0) }.reduce(0, +)
        let variance = sumOfSquaredDifferences / Double(samples.count - 1)
        
        return sqrt(variance)
    }
}
class ThroughputEstimator: NSObject, URLSessionDataDelegate {
    private var startTime: CFAbsoluteTime?
    private var receivedBytes: Int64 = 0
    private var completion: ((Double?) -> Void)? // Speed in bps
    
    func measureDownloadSpeed(url: URL, completion: @escaping (Double?) -> Void) {
        self.completion = completion
        self.startTime = CFAbsoluteTimeGetCurrent()
        self.receivedBytes = 0
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        let task = session.dataTask(with: url)
        task.resume()
    }
    
    func measureUploadSpeed(url: URL, data: Data, completion: @escaping (Double?) -> Void) {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let session = URLSession.shared
        let task = session.uploadTask(with: request, from: data) { _, _, error in
            if error != nil {
                completion(nil)
                return
            }
            
            let elapsedTime = CFAbsoluteTimeGetCurrent() - startTime
            let speed = (Double(data.count) * 8) / elapsedTime // bps
            completion(speed)
        }
        task.resume()
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        receivedBytes += Int64(data.count)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        session.invalidateAndCancel()
        guard let startTime = startTime, error == nil else {
            completion?(nil)
            return
        }
        
        let elapsedTime = CFAbsoluteTimeGetCurrent() - startTime
        let speed = (Double(receivedBytes) * 8) / elapsedTime // bps
        completion?(speed)
    }
}

// MARK: - Data Aggregation
class DataAggregator {
    func aggregateSamples(in context: NSManagedObjectContext, forInterval interval: TimeInterval, type: String) async {
        logger.log("Aggregating samples for \(type) interval...")
        
        let fetchRequest: NSFetchRequest<NetworkSample> = NSFetchRequest<NetworkSample>(entityName: "NetworkSample")
        let now = Date()
        let twoHoursAgo = now.addingTimeInterval(-2 * 3600) // Aggregate last 2 hours of raw data
        fetchRequest.predicate = NSPredicate(format: "timestamp >= %@", twoHoursAgo as NSDate)
        
        do {
            let samples = try context.fetch(fetchRequest)
            guard !samples.isEmpty else {
                logger.log("No raw samples to aggregate.")
                return
            }
            
            // Group samples by interval
            let groupedSamples = Dictionary(grouping: samples) { (sample) -> Date in
                let timeSinceStart = sample.timestamp.timeIntervalSince1970 - twoHoursAgo.timeIntervalSince1970
                let intervalIndex = Int(timeSinceStart / interval)
                return twoHoursAgo.addingTimeInterval(Double(intervalIndex) * interval)
            }
            
            for (_, samplesInInterval) in groupedSamples {
                let sortedSamples = samplesInInterval.sorted(by: { $0.timestamp < $1.timestamp })
                guard let firstSampleTime = sortedSamples.first?.timestamp,
                      let lastSampleTime = sortedSamples.last?.timestamp else { continue }
                
                // Aggregate Latency
                let latencies = samplesInInterval.map { $0.latency_avg }
                if let avg = latencies.average(), let min = latencies.min(), let max = latencies.max() {
                    let aggregatedLatency = AggregatedSeries(context: context)
                    aggregatedLatency.timestampStartUTC = firstSampleTime
                    aggregatedLatency.timestampEndUTC = lastSampleTime
                    aggregatedLatency.intervalType = type
                    aggregatedLatency.metricType = "latency"
                    aggregatedLatency.valueAvg = avg
                    aggregatedLatency.valueMin = min
                    aggregatedLatency.valueMax = max
                    // aggregatedLatency.interfaceID = ... (can be added if NetworkSample had it)
                }
                
                // Aggregate Jitter
                let jitters = samplesInInterval.map { $0.jitter_ms }
                if let avg = jitters.average(), let min = jitters.min(), let max = jitters.max() {
                    let aggregatedJitter = AggregatedSeries(context: context)
                    aggregatedJitter.timestampStartUTC = firstSampleTime
                    aggregatedJitter.timestampEndUTC = lastSampleTime
                    aggregatedJitter.intervalType = type
                    aggregatedJitter.metricType = "jitter"
                    aggregatedJitter.valueAvg = avg
                    aggregatedJitter.valueMin = min
                    aggregatedJitter.valueMax = max
                }
                
                // Aggregate Packet Loss
                let packetLosses = samplesInInterval.map { $0.packet_loss_pct }
                if let avg = packetLosses.average(), let min = packetLosses.min(), let max = packetLosses.max() {
                    let aggregatedPacketLoss = AggregatedSeries(context: context)
                    aggregatedPacketLoss.timestampStartUTC = firstSampleTime
                    aggregatedPacketLoss.timestampEndUTC = lastSampleTime
                    aggregatedPacketLoss.intervalType = type
                    aggregatedPacketLoss.metricType = "packetLoss"
                    aggregatedPacketLoss.valueAvg = avg
                    aggregatedPacketLoss.valueMin = min
                    aggregatedPacketLoss.valueMax = max
                }
                
                // Aggregate Download
                let downloads = samplesInInterval.map { $0.download_bps_est }
                if let avg = downloads.average(), let min = downloads.min(), let max = downloads.max() {
                    let aggregatedDownload = AggregatedSeries(context: context)
                    aggregatedDownload.timestampStartUTC = firstSampleTime
                    aggregatedDownload.timestampEndUTC = lastSampleTime
                    aggregatedDownload.intervalType = type
                    aggregatedDownload.metricType = "download"
                    aggregatedDownload.valueAvg = avg
                    aggregatedDownload.valueMin = min
                    aggregatedDownload.valueMax = max
                }
                
                // Aggregate Upload
                let uploads = samplesInInterval.map { $0.upload_bps_est }
                if let avg = uploads.average(), let min = uploads.min(), let max = uploads.max() {
                    let aggregatedUpload = AggregatedSeries(context: context)
                    aggregatedUpload.timestampStartUTC = firstSampleTime
                    aggregatedUpload.timestampEndUTC = lastSampleTime
                    aggregatedUpload.intervalType = type
                    aggregatedUpload.metricType = "upload"
                    aggregatedUpload.valueAvg = avg
                    aggregatedUpload.valueMin = min
                    aggregatedUpload.valueMax = max
                }
            }
            
            try context.save()
            logger.log("Successfully aggregated samples for \(type) interval.")
            
            // Down-sampling: Delete raw samples older than 2 hours that have been aggregated
            let deleteRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "NetworkSample")
            deleteRequest.predicate = NSPredicate(format: "timestamp < %@", twoHoursAgo as NSDate)
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: deleteRequest)
            
            do {
                try context.execute(batchDeleteRequest)
                logger.log("Successfully deleted old raw samples.")
            } catch {
                logger.error("Failed to delete old raw samples: \(error.localizedDescription)")
            }
            
        } catch {
            logger.error("Failed to fetch raw samples for aggregation: \(error.localizedDescription)")
        }
    }
}

// MARK: - System Monitoring

protocol SystemMonitorDelegate: AnyObject {
    func networkDidBecomeReachable()
    func networkDidBecomeUnreachable()
    func systemWillSleep()
    func systemDidWake()
}

class SystemMonitor {
    weak var delegate: SystemMonitorDelegate?
    private var reachability: SCNetworkReachability?

    init() {
        setupReachability()
        setupWorkspaceNotifications()
    }

    private func setupReachability() {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)

        reachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }

        let callback: SCNetworkReachabilityCallBack = { (reachability, flags, info) in
            guard let info = info else { return }
            let monitor = Unmanaged<SystemMonitor>.fromOpaque(info).takeUnretainedValue()
            monitor.reachabilityChanged(flags: flags)
        }

        var context = SCNetworkReachabilityContext(version: 0, info: Unmanaged.passUnretained(self).toOpaque(), retain: nil, release: nil, copyDescription: nil)
        
        if let reachability = reachability, SCNetworkReachabilitySetCallback(reachability, callback, &context) {
            SCNetworkReachabilityScheduleWithRunLoop(reachability, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
        }
    }
    
    private func reachabilityChanged(flags: SCNetworkReachabilityFlags) {
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)

        if isReachable && !needsConnection {
            delegate?.networkDidBecomeReachable()
        } else {
            delegate?.networkDidBecomeUnreachable()
        }
    }

    private func setupWorkspaceNotifications() {
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(systemWillSleep), name: NSWorkspace.willSleepNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(systemDidWake), name: NSWorkspace.didWakeNotification, object: nil)
    }

    @objc private func systemWillSleep() {
        delegate?.systemWillSleep()
    }

    @objc private func systemDidWake() {
        delegate?.systemDidWake()
    }
    
    deinit {
        if let reachability = reachability {
            SCNetworkReachabilityUnscheduleFromRunLoop(reachability, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
        }
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
}


// MARK: - Data Collection and Storage
class DataCollector {
    private let pinger = ICMPPinger()
    private let tcpConnector = TCPConnector()
    private let jitterCalculator = JitterCalculator()
    private let throughputEstimator = ThroughputEstimator()
    
    private var latencySamples: [Double] = []
    private let maxLatencySamples = 10
    
    private let downloadTestURL = URL(string: "https://proof.ovh.net/files/1Mb.dat")!
    private let uploadTestURL = URL(string: "https://www.google.com")!
    
    private var notificationConfiguration: NotificationConfigurationDTO // New property
    
    init(notificationConfiguration: NotificationConfigurationDTO) {
        self.notificationConfiguration = notificationConfiguration
    }
    
    func updateNotificationConfiguration(configuration: NotificationConfigurationDTO) {
        self.notificationConfiguration = configuration
    }
    
    func collectSample(context: NSManagedObjectContext) async {
        logger.log("DataCollector: Collecting and saving new network sample...")
        
        let newSample = NetworkSample(context: context)
        newSample.timestamp = Date()
        
        // 1. Ping
        let pingResult = pinger.ping(host: "1.1.1.1")
        if let rtt = pingResult.rtt, let loss = pingResult.packetLoss {
            newSample.latency_avg = rtt
            newSample.packet_loss_pct = loss
            
            // 2. Jitter
            latencySamples.append(rtt)
            if latencySamples.count > maxLatencySamples {
                latencySamples.removeFirst()
            }
            if let jitter = jitterCalculator.calculate(samples: latencySamples) {
                newSample.jitter_ms = jitter
            }
            
            // 3. Check for latency breach and post notification
            if notificationConfiguration.isEnabled && rtt > notificationConfiguration.latencyThreshold {
                postLatencyNotification(latency: rtt, threshold: notificationConfiguration.latencyThreshold)
            }
        }
        
        // 3. TCP Latency (Not directly stored in this sample, but logged)
        await withCheckedContinuation { continuation in
            tcpConnector.connect(host: "www.apple.com", port: 443) { _ in
                continuation.resume()
            }
        }
        
        // 4. Throughput
        let downloadSpeed = await withCheckedContinuation { (continuation: CheckedContinuation<Double?, Never>) -> Void in
            throughputEstimator.measureDownloadSpeed(url: downloadTestURL) { speed in
                continuation.resume(returning: speed)
            }
        }
        newSample.download_bps_est = downloadSpeed ?? 0
        
        let uploadSpeed = await withCheckedContinuation { (continuation: CheckedContinuation<Double?, Never>) -> Void in
            let uploadData = Data(repeating: 0, count: 100 * 1024)
            throughputEstimator.measureUploadSpeed(url: uploadTestURL, data: uploadData) { speed in
                continuation.resume(returning: speed)
            }
        }
        newSample.upload_bps_est = uploadSpeed ?? 0
        
        // Save the context
        do {
            try context.save()
            logger.log("Successfully saved new network sample.")
        } catch {
            logger.error("Failed to save network sample: \(error.localizedDescription)")
        }
    }
    
    private func postLatencyNotification(latency: Double, threshold: Double) {
        let content = UNMutableNotificationContent()
        content.title = "Network Latency Alert!"
        content.body = String(format: "Latency %.2f ms exceeded your threshold of %.0f ms.", latency, threshold)
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                logger.error("Error posting notification: \(error.localizedDescription)")
            } else {
                logger.log("Latency notification posted.")
            }
        }
    }
}

// MARK: - Main Agent Class
class NetworkMonitorAgent: NSObject, NetworkMonitorAgentProtocol, SystemMonitorDelegate {

    private var measurementTimer: Timer?
    private var aggregationTimer: Timer?
    private lazy var collector: DataCollector = DataCollector(notificationConfiguration: self.notificationConfiguration) // Initialize collector with config
    private let aggregator = DataAggregator()
    private let persistenceController = PersistenceController.shared
    private var systemMonitor: SystemMonitor?
    
    // MARK: - Notification Configuration Methods
    private var notificationConfiguration = NotificationConfigurationDTO(isEnabled: false, latencyThreshold: 100.0, packetLossThreshold: 5.0, consecutiveFailuresThreshold: 3) {
        didSet {
            collector.updateNotificationConfiguration(configuration: notificationConfiguration) // Update collector when config changes
        }
    }

    override init() {
        super.init()
        logger.log("NetworkMonitorAgent initialized.")
        systemMonitor = SystemMonitor()
        systemMonitor?.delegate = self
        resumeMeasurements()
        startAggregationTimer()
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                logger.log("Notification authorization granted.")
            } else if let error = error {
                logger.error("Notification authorization failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Measurement Control
    
    @objc func collectAndSaveSample() {
        Task {
            await collector.collectSample(context: persistenceController.newBackgroundTask())
        }
    }

    func resumeMeasurements() {
        guard measurementTimer == nil || !measurementTimer!.isValid else {
            logger.log("Measurements are already running.")
            return
        }
        logger.log("Resuming measurements.")
        collectAndSaveSample() // Run immediately
        measurementTimer = Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(collectAndSaveSample), userInfo: nil, repeats: true)
    }

    func pauseMeasurements() {
        logger.log("Pausing measurements.")
        measurementTimer?.invalidate()
        measurementTimer = nil
    }

    func startAggregationTimer() {
        aggregationTimer = Timer.scheduledTimer(withTimeInterval: 300.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let context = self.persistenceController.newBackgroundTask()
            Task {
                await self.aggregator.aggregateSamples(in: context, forInterval: 300.0, type: "5m")
                await self.aggregator.aggregateSamples(in: context, forInterval: 3600.0, type: "1h")
            }
        }
    }

    // MARK: - NetworkMonitorAgentProtocol Conformance

    func startMonitoring() {
        resumeMeasurements()
    }

    func stopMonitoring() {
        pauseMeasurements()
    }

    func getStatus(completion: @escaping (String) -> Void) {
        let status = (measurementTimer?.isValid ?? false) ? "Running" : "Stopped"
        completion(status)
    }

    func getSamples(completion: @escaping (Data) -> Void) {
        let context = persistenceController.newBackgroundTask()
        let endDate = Date()
        let startDate = endDate.addingTimeInterval(-3600) // Last hour
        context.perform {
            let fetchRequest: NSFetchRequest<NetworkSample> = NSFetchRequest<NetworkSample>(entityName: "NetworkSample")
            fetchRequest.predicate = NSPredicate(format: "timestamp >= %@ AND timestamp <= %@", startDate as NSDate, endDate as NSDate)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
            
            do {
                let managedSamples = try context.fetch(fetchRequest)
                let dtos = managedSamples.map { NetworkSampleDTO(timestamp: $0.timestamp, latency: $0.latency_avg, packetLoss: $0.packet_loss_pct, connectivity: true) }
                let data = try JSONEncoder().encode(dtos)
                completion(data)
            } catch {
                logger.error("Failed to fetch samples: \(error.localizedDescription)")
                completion(try! JSONEncoder().encode([NetworkSampleDTO]()))
            }
        }
    }

    func getAggregatedSamples(completion: @escaping (Data) -> Void) {
        let context = persistenceController.newBackgroundTask()
        let endDate = Date()
        let startDate = endDate.addingTimeInterval(-2 * 3600) // Last 2 hours
        let intervalType = "5m"
        let metricType = "latency"
        context.perform {
            let fetchRequest: NSFetchRequest<AggregatedSeries> = NSFetchRequest<AggregatedSeries>(entityName: "AggregatedSeries")
            let predicates = [
                NSPredicate(format: "timestampStartUTC >= %@", startDate as NSDate),
                NSPredicate(format: "timestampStartUTC <= %@", endDate as NSDate),
                NSPredicate(format: "intervalType == %@", intervalType),
                NSPredicate(format: "metricType == %@", metricType)
            ]
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestampStartUTC", ascending: true)]
            
            do {
                let managedSeries = try context.fetch(fetchRequest)
                let points = managedSeries.map { GraphPoint(date: $0.timestampStartUTC, value: $0.valueAvg) }
                let dto = AggregatedSeriesDTO(metric: metricType, data: points)
                let data = try JSONEncoder().encode([dto])
                completion(data)
            } catch {
                logger.error("Failed to fetch aggregated samples: \(error.localizedDescription)")
                completion(try! JSONEncoder().encode([AggregatedSeriesDTO]()))
            }
        }
    }

    func getNotificationConfiguration(completion: @escaping (Data) -> Void) {
        do {
            let data = try JSONEncoder().encode(self.notificationConfiguration)
            completion(data)
        } catch {
            logger.error("Failed to encode notification configuration: \(error.localizedDescription)")
            completion(Data())
        }
    }

    func setNotificationConfiguration(_ configuration: Data, completion: @escaping () -> Void) {
        do {
            self.notificationConfiguration = try JSONDecoder().decode(NotificationConfigurationDTO.self, from: configuration)
            logger.log("Updated notification configuration.")
        } catch {
            logger.error("Failed to decode notification configuration: \(error.localizedDescription)")
        }
        completion()
    }

    // MARK: - SystemMonitorDelegate
    
    func networkDidBecomeReachable() {
        logger.log("Network became reachable. Resuming measurements.")
        resumeMeasurements()
    }
    
    func networkDidBecomeUnreachable() {
        logger.log("Network became unreachable. Pausing measurements.")
        pauseMeasurements()
    }
    
    func systemWillSleep() {
        logger.log("System will sleep. Pausing measurements.")
        pauseMeasurements()
    }
    
    func systemDidWake() {
        logger.log("System did wake. Resuming measurements.")
        resumeMeasurements()
    }
}
