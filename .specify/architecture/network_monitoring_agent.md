# Network Monitoring Agent Implementation

## 1. Overview

The Network Monitoring Agent (`NetworkMonitorAgent`) is the backbone of the Speckit Network Monitor application. It operates silently in the background, continuously collecting network performance data, processing it, and storing it in the local Core Data (SQLite) store. This document details its architecture, measurement techniques, and integration points.

## 2. Agent Lifecycle & Management

*   **Deployment**: The agent will be deployed as an `XPC Service` bundled within the main application. This provides robust lifecycle management, security sandboxing, and efficient IPC with the main app.
*   **Activation**: The main application will be responsible for activating and deactivating the XPC Service. `SMAppService` (macOS 13+) will be used for persistent background execution, ensuring the agent automatically launches on system startup and restarts if terminated unexpectedly. For older macOS versions, `LaunchAgents` could be considered as a fallback, but `SMAppService` is preferred due to its modern capabilities and integration with system settings.
*   **Background Execution**: The agent will leverage `DispatchSource` timers or `Timer` objects with appropriate `qos` (Quality of Service) to schedule periodic measurements, minimizing impact on system resources.

## 3. Network Measurement Logic

The agent will implement the following measurement techniques to capture comprehensive network performance data:

### 3.1. Latency & Packet Loss (ICMP/TCP)

*   **ICMP Ping**: For general latency and packet loss, the agent will send ICMP echo requests to a configurable target (e.g., default gateway, public DNS server like 1.1.1.1, 8.8.8.8). `Network.framework` (specifically `NWConnection`) will be used for low-level socket operations to send and receive ICMP packets.
    *   **Metrics**: Round-trip time (RTT) for latency, and count of lost packets for packet loss percentage.
    *   **Implementation**: A custom `ICMPPinger` class will manage a sequence of pings, calculate average, min, max latency, and packet loss over a measurement interval.
*   **TCP Connect Latency**: To measure latency to a specific TCP service (e.g., a web server), the agent will attempt to establish a TCP connection to a well-known port (e.g., 443 for HTTPS) on a target host. The time taken for the handshake will represent TCP connect latency.
    *   **Metrics**: TCP connection establishment time.
    *   **Implementation**: A `TCPConnector` class utilizing `Network.framework` for connection attempts with a short timeout.

### 3.2. Jitter

*   **Calculation**: Jitter will be calculated as the standard deviation of latency measurements (typically ICMP RTTs) within a given sampling interval. A larger standard deviation indicates higher jitter.
    *   **Metrics**: Jitter in milliseconds.
    *   **Implementation**: The `ICMPPinger` or a dedicated `JitterCalculator` will process a series of latency samples to derive jitter.

### 3.3. Throughput Estimation (Upload/Download)

*   **Method**: Throughput will be estimated by performing controlled, short-duration data transfers to and from a known, reliable server (e.g., a custom speed test endpoint or a public CDN with small test files).
    *   **Upload**: Send a fixed-size buffer of data and measure the time taken.
    *   **Download**: Download a fixed-size file and measure the time taken.
*   **Resource Impact**: Measurements must be small and infrequent enough to avoid significantly impacting user's network experience (`Notes & Tradeoffs` in `speckit.specify`). This may involve adaptive scheduling or user-configurable limits.
*   **Technology**: `URLSession` (for high-level HTTP transfers) or `Network.framework` (for more control over low-level data transfer) will be used.
    *   **Metrics**: Upload and download speeds in bits per second (bps).

## 4. Data Storage & Aggregation

*   **Data Persistence**: After each measurement interval, the collected raw `NetworkSample` data will be saved to the Core Data store via the `CoreDataNetworkDataStore` (as defined in `data_layer.md`). This will occur on a private background `NSManagedObjectContext` to prevent UI blocking.
*   **Background Aggregation**: The agent will periodically trigger a background process (e.g., hourly) to aggregate older raw `NetworkSample` data into `AggregatedSeries` entries. This includes:
    *   Calculating averages, mins, and maxes for metrics over 5-minute, 1-hour, and 1-day intervals.
    *   Down-sampling: Deleting raw `NetworkSample` entries that have already been aggregated and exceed the raw data retention policy (e.g., after 7 days, raw samples are removed once aggregated).
*   **Error Handling**: Robust error handling for network failures, disk I/O issues, and Core Data save operations to ensure data integrity.

## 5. System Configuration Monitoring

*   **Network Change Detection**: `SystemConfiguration.framework` (`SCNetworkReachability` and `SCDynamicStore`) will be used to monitor changes in network connectivity (e.g., Wi-Fi / Ethernet changes, connection status). The agent will adapt its measurement strategy or pause monitoring when no active internet connection is detected.
*   **System Sleep/Wake**: The agent will subscribe to `NSWorkspace` notifications (e.g., `NSWorkspaceDidWakeNotification`, `NSWorkspaceWillSleepNotification`) to pause measurements during sleep and resume upon wake, ensuring accurate data and resource conservation.

## 6. IPC Communication with Main Application

*   **XPC Service API**: The `NetworkMonitorAgent` will expose a well-defined XPC protocol (`NetworkMonitorAgentProtocol`) that the main application can use to:
    *   Request current network status and real-time data.
    *   Fetch historical `NetworkSample` and `AggregatedSeries` data for specific time ranges.
    *   Receive notifications about significant network events or service status changes.
    *   Update monitoring configuration (e.g., sampling frequency, targets).
*   **Security**: XPC Services inherently provide sandboxing and code-signing validation, ensuring secure communication channels.

## 7. Resource Optimization

*   **Low Memory Footprint**: Minimize object allocations, use value types where appropriate, and ensure proper ARC (Automatic Reference Counting) management. Implement memory warnings handling (`applicationDidReceiveMemoryWarning`).
*   **Efficient CPU Usage**: Use `DispatchSource` or `Timer` with appropriate `qos` (Quality of Service) to schedule background tasks. Avoid tight loops or blocking operations on the main thread.
*   **Disk I/O**: Optimize Core Data writes with batching and efficient fetch requests to reduce disk I/O and extend device battery life.

## 8. Security & Privacy

*   **Sandboxing**: The XPC Service will operate under its own sandbox, with specific entitlements only for network access and communication with the main app.
*   **No Inbound Connections**: The agent will strictly adhere to `NFR-004` and `SEC-003`, never opening inbound network ports or performing local network scanning.
*   **Data Protection**: Ensure local data in Core Data is protected using macOS Data Protection APIs if applicable. Avoid logging sensitive information.

