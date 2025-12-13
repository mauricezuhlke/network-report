# Background Data Collection Implementation

## 1. Overview

This document details the implementation of the background data collection within the Network Monitoring Agent. The primary goal is to ensure continuous, silent, and resource-efficient collection, processing, and storage of network performance metrics, strictly adhering to the specified low memory and CPU Non-Functional Requirements (NFRs).

## 2. Measurement Scheduling and Execution

*   **Intervals**: Data collection will occur at configurable intervals (default 1 minute, as per `FR-001`). This interval can be adjusted via the main application's settings, communicated via XPC to the agent.
*   **Scheduling Mechanism**: `DispatchSource` timers will be used for precise and energy-efficient periodic task scheduling. These timers can be configured with appropriate Quality of Service (QoS) classes (e.g., `background`) to minimize impact on user-interactive tasks.
*   **Concurrency**: Network measurements are I/O-bound operations. They will be performed on dedicated `DispatchQueues` (e.g., `qosUserInitiated` for active throughput tests, `qosBackground` for passive latency/packet loss) to prevent blocking the main application or other agent tasks.
*   **Adaptive Sampling**: The agent will implement logic to adapt its sampling frequency based on system conditions:
    *   **System Sleep/Wake**: Pause measurements on `NSWorkspaceWillSleepNotification` and resume on `NSWorkspaceDidWakeNotification` to conserve power and avoid collecting invalid data during sleep.
    *   **Network Unavailability**: Pause measurements if `SystemConfiguration.framework` reports no active network connection, resuming when connectivity is restored.
    *   **High CPU/Memory Load**: Optionally, temporarily reduce sampling frequency if system-wide CPU or memory pressure is detected, adhering to `NFR-001` and `NFR-002`.

## 3. Data Processing and Storage Workflow

### 3.1. Raw Sample Collection

1.  **Measurement Execution**: At each scheduled interval, the agent will execute the network measurement logic (ICMP ping, TCP connect, throughput estimation) as detailed in `network_monitoring_agent.md`.
2.  **Result Aggregation**: Individual measurement results (e.g., multiple pings within an interval) will be aggregated into a single `NetworkSample` object, calculating average, min, max latency, and total packet loss for that interval.
3.  **Core Data Insertion**: The `NetworkSample` object will be inserted into the Core Data store via the `CoreDataNetworkDataStore` (using a background `NSManagedObjectContext`). This ensures that UI remains responsive and database operations are non-blocking.

### 3.2. Background Aggregation and Down-sampling

*   **Scheduler**: A separate, less frequent `DispatchSource` timer (e.g., hourly) will trigger the aggregation process.
*   **Aggregation Logic**: For each metric (latency, packet loss, throughput), the agent will query raw `NetworkSample` data that falls within a specific aggregation window (e.g., the last 5 minutes, last hour, last day). It will then calculate `AggregatedSeries` entries (`valueAvg`, `valueMin`, `valueMax`) for these intervals.
*   **Down-sampling**: Once raw `NetworkSample` data has been successfully aggregated into higher-level `AggregatedSeries` (e.g., 5-minute averages, 1-hour averages), and it falls outside the raw data retention window (e.g., older than 7 days), the raw samples will be deleted from the Core Data store. This is crucial for managing storage footprint (`NFR-003`).
*   **Transaction Management**: Core Data save operations for aggregation and deletion will be batched into single transactions where possible to improve performance and ensure atomicity.

## 4. Resource Efficiency (Adhering to NFRs)

*   **Memory (`NFR-001`)**:
    *   **Minimal Object Graph**: Keep `NetworkSample` and `AggregatedSeries` entities lightweight. Avoid storing redundant or large data within Core Data entities.
    *   **Batching**: When fetching or saving large numbers of objects for aggregation, use Core Data's batching capabilities (`NSBatchUpdateRequest`, `NSBatchDeleteRequest`) to minimize memory usage.
    *   **Memory Warnings**: Implement `applicationDidReceiveMemoryWarning` to potentially flush caches or reduce in-memory data if the system is under memory pressure.
*   **CPU (`NFR-002`)**:
    *   **QoS**: Use appropriate QoS for `DispatchQueues` to prioritize background tasks lower than user-initiated tasks.
    *   **Efficient Algorithms**: Ensure aggregation and data processing algorithms are optimized for performance, avoiding unnecessary loops or computations.
    *   **Throttling**: Implement logic to throttle network measurements or aggregation tasks if CPU usage consistently exceeds the defined budget.
*   **Storage (`NFR-003`)**:
    *   **Aggressive Down-sampling**: The down-sampling strategy is the primary mechanism to control disk usage. Ensure it is robust and consistently applied.
    *   **Configurable Retention**: Provide user settings to adjust raw data retention and aggregated data retention periods, allowing users to balance data granularity with storage limits.

## 5. Error Handling and Reliability

*   **Network Errors**: Gracefully handle network unavailability, timeouts, and other connection errors during measurements. Log errors for debugging without crashing the agent.
*   **Core Data Errors**: Implement robust error handling for Core Data save/fetch operations. Use `try/catch` blocks and log failures. Ensure database consistency after crashes by leveraging Core Data's journaling capabilities.
*   **Crash Reporting**: Integrate a lightweight, privacy-focused crash reporting mechanism (if user opt-in for telemetry) to identify and fix agent stability issues.

## 6. IPC Interaction

*   **Status Updates**: The agent will use its XPC connection to send periodic status updates (e.g., `isMonitoring`, `lastMeasurementTime`, `currentNetworkStatus`) to the main application for UI display.
*   **Configuration Sync**: The main application will send updated settings (e.g., measurement interval, aggregation policy) to the agent via XPC, which the agent will then apply.

