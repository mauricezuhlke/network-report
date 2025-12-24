# Quickstart: MVP XPC Connection Test

This guide explains how to run the `NetworkReporter` application and test the XPC connection feature.

## Prerequisites

- A Mac with Xcode installed.
- The code checked out to the `updated-xpc` branch.

## Running the Application

1.  **Open the project**: In Finder, navigate to the project root and open `NetworkReporter/NetworkReporter.xcodeproj`.
2.  **Select the target**: In Xcode's toolbar, ensure the `NetworkReporter` scheme is selected and the target device is "My Mac".
3.  **Run the app**: Click the "Run" button (or press `Cmd+R`). Xcode will build both the main application and the XPC service.

## Testing the Feature

### 1. Success Case

1.  Once the application window appears, you will see a button.
2.  Click the button (the label will be implemented based on the plan, e.g., "Get Timestamp").
3.  Observe the text view below the button. Upon a successful connection to the XPC service, it will display the current timestamp in ISO 8601 format (e.g., `2025-12-24T18:30:00Z`).

### 2. Failure Case (Simulated)

1.  With the app still running, look at the Debug bar at the bottom of the Xcode window. You will see two processes: `NetworkReporter` and `NetworkReporterService`.
2.  Click on `NetworkReporterService` in the Debug bar, then click the "Stop" button to terminate it.
3.  Return to the `NetworkReporter` application window.
4.  Click the button again.
5.  This time, the text view below the button should display an error message, indicating that the XPC service could not be reached.
