# Quickstart Guide: Network Performance Monitor Feature Development

This guide outlines the steps to get started with developing the Network Performance Monitor feature.

## 1. Checkout the Feature Branch

First, ensure you are on the correct feature branch:

```bash
git checkout 001-network-performance-monitor
```

## 2. Open the Xcode Project

Open the `NetworkReporter.xcodeproj` file located in the `NetworkReporter/` directory using Xcode.

## 3. Understand the Core Components

### Existing Architecture

*   **NetworkReporter (Main Application)**: The primary desktop application responsible for UI and user interaction.
*   **NetworkReporterService (XPC Service)**: A privileged background helper application responsible for performing network monitoring tasks, communicating with the main app via `NetworkReporterServiceProtocol.swift`.

### New Feature Integration

*   **Data Model**: Defined in `specs/001-network-performance-monitor/data-model.md`. This feature introduces the `NetworkPerformanceRecord` entity, which will be persisted using CoreData/SQLite.
*   **Data Collection**: The `NetworkReporterService` will be enhanced to collect and persist `NetworkPerformanceRecord` instances. Note the new **two-way XPC communication** where the service now calls back to the main app using `NetworkReporterClientProtocol` to deliver real-time records.
*   **Data Presentation**: The main `NetworkReporter` application will be updated to fetch historical `NetworkPerformanceRecord` data and display it using native MacOS UI components for charts and graphs. The `ConnectivityStatus` enum (`NetworkReporter/NetworkReporter/Models/NetworkPerformanceRecord+CoreData.swift`) is used to represent connection states.

## 4. Key Development Areas

*   **CoreData Integration**: Set up CoreData stack in `NetworkReporter/NetworkReporter/Persistence.swift` to manage `NetworkPerformanceRecord` storage in SQLite. Includes data purging logic for 18-month retention.
*   **Monitoring Logic Enhancement**: Update `NetworkReporterService/NetworkReporterService.swift` to collect `UploadSpeed` and `DownloadSpeed` metrics, implement `startMonitoring`/`stopMonitoring`, and utilize the two-way XPC to send `NetworkPerformanceRecord` instances to the main app.
*   **UI Development**: Implement new SwiftUI/AppKit views in `NetworkReporter/NetworkReporter/Views/` (e.g., `RealTimeNetworkView.swift`, `HistoricalDataView.swift`) to display real-time metrics and historical charts.
*   **Charting Implementation**: Utilize native MacOS `Charts` framework (for macOS 13+) or custom drawing with Core Graphics to render the historical data visually, including highlighting degraded periods based on defined thresholds.
*   **XPC Client Refactoring**: `NetworkReporter/NetworkReporter/XPCClient.swift` has been refactored to maintain a persistent connection, act as an `ObservableObject`, and implement `NetworkReporterClientProtocol` to receive data from the service.

## 5. Running the Application

Build and run both the `NetworkReporter` app target and the `NetworkReporterService` XPC Service target in Xcode. Ensure both are configured and running correctly for full functionality.

## 6. Testing

Refer to `NetworkReporterTests/NetworkReporterTests.swift` for existing unit tests and newly added tests for CoreData persistence and `NetworkReporterService` interaction.
*   Data persistence logic (CoreData/SQLite).
*   Network performance metric collection and XPC communication in `NetworkReporterService` and `XPCClient`.
*   UI rendering of charts and historical data.
*   End-to-end data flow from service to UI.