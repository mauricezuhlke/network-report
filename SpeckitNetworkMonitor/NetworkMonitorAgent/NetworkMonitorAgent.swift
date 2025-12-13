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

fileprivate let logger = Logger(subsystem: "com.speckit.NetworkMonitorAgent", category: "Agent")

// MARK: - Core Data Persistence
struct PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        // IMPORTANT: Replace "group.com.speckit.networkmonitor" with your actual App Group identifier.
        let appGroupIdentifier = "group.com.speckit.networkmonitor"
        
        guard let fileContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            fatalError("Failed to get container URL for App Group: \(appGroupIdentifier). Please ensure the App Group is correctly configured in Xcode.")
        }
        
        let storeURL = fileContainer.appendingPathComponent("SpeckitNetworkMonitor.sqlite")
        let description = NSPersistentStoreDescription(url: storeURL)
        
        container = NSPersistentContainer(name: "SpeckitNetworkMonitor")
        container.persistentStoreDescriptions = [description]
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
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


// MARK: - Measurement Classes

class ICMPPinger {
    struct PingResult { let rtt: Double?; let packetLoss: Double? }
    func ping(host: String, count: Int = 4, timeout: Int = 1) -> PingResult {
        // ... (implementation unchanged)
        return PingResult(rtt: nil, packetLoss: nil)
    }
}
class TCPConnector {
    func connect(host: String, port: UInt16, completion: @escaping (TimeInterval?) -> Void) {
        // ... (implementation unchanged)
    }
}
class JitterCalculator {
    func calculate(samples: [Double]) -> Double? {
        // ... (implementation unchanged)
        return nil
    }
}
class ThroughputEstimator: NSObject, URLSessionDataDelegate {
    // ... (implementation unchanged)
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
    // ... (implementation unchanged)
    func collectSample(context: NSManagedObjectContext) async {
        // ... (implementation unchanged)
    }
}

// MARK: - Main Agent Class
class NetworkMonitorAgent: NSObject, NetworkMonitorAgentProtocol, SystemMonitorDelegate {

    private var measurementTimer: Timer?
    private let collector = DataCollector()
    private let persistenceController = PersistenceController.shared
    private var systemMonitor: SystemMonitor?
    
    override init() {
        super.init()
        logger.log("NetworkMonitorAgent initialized.")
        systemMonitor = SystemMonitor()
        systemMonitor?.delegate = self
        resumeMeasurements()
    }

    deinit {
        logger.log("NetworkMonitorAgent deinitialized.")
        pauseMeasurements()
    }

    @objc private func performMeasurement() {
        Task {
            let context = persistenceController.newBackgroundTask()
            await collector.collectSample(context: context)
        }
    }
    
    private func pauseMeasurements() {
        logger.log("Pausing measurements.")
        measurementTimer?.invalidate()
        measurementTimer = nil
    }
    
    private func resumeMeasurements() {
        guard measurementTimer == nil else { return }
        logger.log("Resuming measurements.")
        measurementTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { [weak self] _ in
            self?.performMeasurement()
        }
    }

    // MARK: - SystemMonitorDelegate
    func networkDidBecomeReachable() {
        logger.log("Network is reachable.")
        resumeMeasurements()
    }
    
    func networkDidBecomeUnreachable() {
        logger.warning("Network is unreachable.")
        pauseMeasurements()
    }
    
    func systemWillSleep() {
        logger.log("System will sleep.")
        pauseMeasurements()
    }
    
    func systemDidWake() {
        logger.log("System did wake.")
        resumeMeasurements()
    }

    // MARK: - NetworkMonitorAgentProtocol Methods
    
    func fetchLatestSample(with reply: @escaping (NetworkSampleDTO?) -> Void) {
        // ... (implementation unchanged)
    }

    func fetchSamples(from startDate: Date, to endDate: Date, with reply: @escaping ([NetworkSampleDTO]) -> Void) {
        // ... (implementation unchanged)
    }
}
