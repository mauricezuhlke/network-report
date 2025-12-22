# Implementation Plan: Network Reporter MVP

**Branch**: `feat/xpc-timestamp` | **Date**: 2025-12-22 | **Spec**: [.specify/specs/speckit.specify](.specify/specs/speckit.specify)

## Summary

This plan outlines the next steps for building the Network Reporter application, starting with the foundational goal of establishing robust communication between the main SwiftUI application and its background XPC service.

The immediate next step is to implement a simple "heartbeat" function: the main app will request the current timestamp from the XPC service, and the service will return it. This will verify the end-to-end connection is working correctly, fulfilling the first success criterion of the current iteration.

## Technical Context

**Language/Version**: Swift 5.9
**Primary Dependencies**: SwiftUI, XPC, Swift Charts
**Storage**: SQLite (using GRDB.swift or a similar wrapper)
**Testing**: XCTest
**Target Platform**: macOS 13+
**Project Type**: macOS Application with a background XPC Service.
**Performance Goals**: XPC service memory footprint <50 MB and average CPU usage <2%.
**Constraints**: All data stored locally. The connection between app and service must be resilient.
**Scale/Scope**: MVP focused on core metrics (latency, packet loss) visualization.

## Constitution Check

The proposed plan adheres to the project constitution. It emphasizes a **small, incremental change** to **measure and verify** the XPC connection. This follows the principles of **Clarity & Simplicity** and **Design for Evolution** by building upon a validated foundation. No violations are noted.

## Project Structure

### Source Code

The project will follow the standard Xcode structure for a macOS app with an XPC service.

```text
NetworkReporter/
├── NetworkReporter/
│   ├── ContentView.swift           # Main app view
│   ├── NetworkReporterApp.swift    # App entry point
│   └── ...
├── NetworkReporterService/
│   ├── main.swift                  # XPC Service entry point
│   ├── NetworkReporterService.swift # XPC Service implementation
│   └── ...
├── NetworkReporter.xcodeproj/
└── ...
```

**Structure Decision**: The existing Xcode-generated structure is appropriate for this project, clearly separating the application target from the XPC service target.

## Implementation Steps

### Phase 1: Verify XPC Connection (Current Task)

1.  **DONE** - Define the `NetworkReporterServiceProtocol` with a simple function to get data.
2.  **DONE** - Implement the initial XPC connection logic in the `ContentView`.
3.  **IN PROGRESS** - **Modify `NetworkReporterService`**: Implement the protocol method to return the current timestamp.
4.  **NEXT** - **Modify `ContentView`**:
    *   Add a `@State` variable to store the timestamp received from the service.
    *   Update the button's action to call the XPC service's timestamp method.
    *   Display the returned timestamp string in the UI.
    *   Ensure the UI gracefully handles a nil or error response.

### Phase 2: Implement Core Metrics

5.  **TODO** - **Modify Protocol**: Extend `NetworkReporterServiceProtocol` with a function to perform a network ping and return latency.
6.  **TODO** - **Implement Ping Logic**: In the XPC service, implement the ping functionality to a reliable host (e.g., 8.8.8.8).
7.  **TODO** - **UI Update**: Display the returned latency in the main app's UI.

### Phase 3: Data Persistence & Charting

8.  **TODO** - **Add Persistence**: Integrate SQLite (e.g., using `GRDB.swift`) into the XPC service to store timestamped latency results.
9.  **TODO** - **Background Monitoring**: Set up a timer in the XPC service to automatically collect metrics every few seconds.
10. **TODO** - **Data Fetching**: Add a method to the protocol to fetch historical data from the database.
11. **TODO** - **Add Chart**: Use SwiftUI Charts in `ContentView` to display the historical latency data.
