# macOS Network Monitor Application Architecture

## 1. Overview

This document outlines the core architecture for the Speckit Home Office Network Monitor macOS application. The application will consist of a lightweight, persistent background agent for data collection and a user-facing UI for visualization and configuration. Emphasis is placed on native macOS tooling, low resource consumption, and robust security.

## 2. Core Components

### 2.1. Background Agent (NetworkMonitorAgent)

*   **Purpose**: Perform periodic network performance measurements, store data locally, and manage system interactions (e.g., wake from sleep, network changes).
*   **Technology**: Implemented as a Swift/Objective-C background service. Preferred mechanism is `SMAppService` for modern macOS versions, falling back to `LaunchAgents` for broader compatibility if needed.
*   **Key Responsibilities**:
    *   **Network Measurement**: Utilize `Network.framework` for lower-level socket operations and `SystemConfiguration.framework` for network status changes. Implement ICMP ping for latency/packet loss, TCP connect for latency, and custom small file transfers for throughput estimation.
    *   **Data Collection & Aggregation**: Collect raw samples (latency, jitter, packet loss, throughput) at configurable intervals (e.g., 1 minute). Perform on-device aggregation (e.g., 5-minute, 1-hour, daily averages) to optimize storage and query performance for historical charts.
    *   **Local Data Storage**: Interact with the SQLite database (via Core Data with SQLite store or a direct wrapper like FMDB/GRDB) to persist raw and aggregated network samples.
    *   **Resource Management**: Optimize for minimal CPU and memory usage. Implement intelligent sampling (e.g., backoff during high CPU load, adaptive intervals based on network state).
    *   **Communication with UI**: Establish a secure inter-process communication (IPC) channel with the main application, likely using `XPC Services` or `Distributed Objects` for efficient and sandboxed data exchange.

### 2.2. Main Application (Speckit Network Monitor UI)

*   **Purpose**: Provide a user interface for viewing real-time and historical network performance charts, configuring monitoring settings, and generating reports.
*   **Technology**: Built using SwiftUI for a modern, responsive macOS experience. AppKit may be used for specific integrations (e.g., `NSStatusItem`).
*   **Key Responsibilities**:
    *   **Data Presentation**: Render interactive charts for latency, jitter, packet loss, and throughput across various time ranges (hour, day, week, month). Support zooming, panning, and detail views on hover.
    *   **Time-Travel Functionality**: Implement a date/time picker to navigate historical data, displaying detailed samples for specific periods.
    *   **User Configuration**: Provide settings for monitoring frequency, data retention policies, privacy options (e.g., opt-in cloud sync), and notification preferences.
    *   **Native Notifications**: Utilize `UNUserNotificationCenter` for system-level alerts (e.g., network degradation, service status).
    *   **System Tray Integration**: Implement `NSStatusItem` for a menubar icon, offering quick access to status and core functions.
    *   **Report Generation**: Generate exportable PDF/CSV reports of selected data ranges for ISP communication, ensuring options for data redaction.
    *   **IPC Client**: Communicate with the Background Agent to request data, send configuration updates, and receive status notifications.

## 3. Data Layer

*   **Primary Store**: SQLite database for local persistence. Core Data will be the preferred framework for abstraction, using SQLite as its persistent store.
*   **Schema**: 
    *   `NetworkSample` (timestamp, latency_avg, latency_min, latency_max, packet_loss_pct, jitter_ms, upload_bps_est, download_bps_est, interface_id, sample_method, confidence)
    *   `AggregatedSeries` (timestamp_start, timestamp_end, interval_type (e.g., 5m, 1h), metric_type, value_avg, value_min, value_max)
*   **Retention**: Implement rolling retention policies at the database level, down-sampling older raw data into aggregated series to manage storage footprint (e.g., raw for 7 days, 5m for 30 days, 1h for 6 months, 1d for 1 year).

## 4. Inter-Process Communication (IPC)

*   **Mechanism**: `XPC Services` is the primary choice for secure and efficient communication between the sandboxed main application and the background agent. This provides proper entitlements, security, and lifecycle management.
*   **Data Exchange**: Define a clear API for requesting historical data, subscribing to real-time updates, and sending configuration changes.

## 5. Security & Privacy

*   **App Sandboxing**: The main application will be sandboxed to limit its access to system resources.
*   **Data Protection**: Use `Keychain Services` for storing any sensitive user configuration or encryption keys. Local data (SQLite) will be encrypted if deemed sensitive, potentially leveraging macOS Data Protection APIs.
*   **Network Access**: The background agent will be strictly limited to outbound connections for network measurement. No inbound ports will be opened, and no local network scanning or enumeration of other devices will occur (`SEC-003`).
*   **Consent**: All optional features (e.g., cloud sync, telemetry) will require explicit user consent via clear UI prompts.

## 6. Performance Considerations

*   **Memory Management**: Aggressive optimization for memory footprint, particularly in the background agent. Use value types, efficient data structures, and avoid memory leaks.
*   **CPU Cycles**: Background agent operations will be scheduled using `DispatchSource` or `Timer` with appropriate `qos` (Quality of Service) to minimize impact on system responsiveness.
*   **Efficient Data Loading**: Implement lazy loading and virtualized scrolling for charts with large datasets to ensure smooth UI performance.

## 7. Deployment & Updates

*   **Packaging**: Standard macOS Application Bundle, potentially with a helper tool (the background agent) embedded. Distribution via App Store (if feasible) or notarized direct download.
*   **Updates**: Implement an auto-update mechanism (e.g., `Sparkle framework`) for direct downloads, ensuring integrity with code signing.

## 8. Testing Strategy

*   **Unit Tests**: For core logic, data models, aggregation, and IPC message handling.
*   **Integration Tests**: Validate data flow from agent -> database -> UI, and verify chart rendering against known data.
*   **Performance Tests**: Monitor memory, CPU, and disk I/O under various load conditions.
*   **Security Audits**: Regular code reviews and static analysis for security vulnerabilities.

