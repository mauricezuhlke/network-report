# Tasks: Speckit Network Monitor

**Input**: `/Users/maro/Documents/Projects/SDD/network-report/.specify/architecture/architecture.md`
**Prerequisites**: The architecture plan is approved. The Xcode project is already initialized.

**Organization**: Tasks are grouped by user story to enable independent, incremental implementation.

---

## Phase 1: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that must be complete before any user story can be implemented.

- [x] T001 Define the XPC service protocol in `SpeckitNetworkMonitor/NetworkMonitorAgent/NetworkMonitorAgentProtocol.swift`. This contract is critical for UI-agent communication.
- [x] T002 Implement the Core Data model (`.xcdatamodeld`) with `NetworkSample` and `AggregatedSeries` entities as defined in the architecture. Location: `SpeckitNetworkMonitor/SpeckitNetworkMonitor/SpeckitNetworkMonitor.xcdatamodeld`.
- [x] T003 [P] Setup the basic `NetworkMonitorAgent` service in `SpeckitNetworkMonitor/NetworkMonitorAgent/main.swift` and `NetworkMonitorAgent.swift` to run as a background `SMAppService`.
- [x] T004 Setup the basic UI structure in `SpeckitNetworkMonitor/SpeckitNetworkMonitor/ContentView.swift` to connect to the XPC service.
- [x] T005 Implement the persistence controller in `SpeckitNetworkMonitor/SpeckitNetworkMonitor/Persistence.swift` to manage the Core Data stack.

**Checkpoint**: Foundation ready. The agent can run, and the UI can connect to it via XPC. The database is set up.

---

## Phase 2: User Story 1 - Real-time Latency (Priority: P1) 🎯 MVP

**Goal**: As a user, I want to see my real-time network latency in a simple chart so I can know the current health of my network.
**Independent Test**: The chart on the UI updates every few seconds with a new latency value retrieved from the background agent.

### Tests for User Story 1

- [ ] T006 [US1] Write a unit test to verify the ICMP ping logic correctly measures latency.
- [ ] T007 [US1] Write a UI test to ensure the `ContentView` correctly displays a sample data point provided by a mocked XPC service.

### Implementation for User Story 1

- [x] T008 [US1] Implement ICMP ping logic within the `NetworkMonitorAgent.swift` to collect latency samples.
- [x] T009 [US1] Store the collected latency samples in the Core Data database via the persistence controller.
- [x] T010 [US1] Expose a method via the XPC protocol to fetch the most recent latency sample.
- [ ] T011 [US1] [P] In the UI, create a simple SwiftUI chart in `ContentView.swift` to display time-series data.
- [ ] T012 [US1] Connect the `ContentView` chart to the XPC service to periodically fetch and display the latest latency data.

**Checkpoint**: User Story 1 is functional. The main app displays a live-updating chart of network latency.

---

## Phase 3: User Story 2 - Historical Data (Priority: P2)

**Goal**: As a user, I want to view historical data for latency, jitter, and packet loss so I can identify trends and troubleshoot past issues.
**Independent Test**: The user can select a date range and see charts populated with the correct historical data from the database.

### Tests for User Story 2

- [ ] T013 [US2] Write unit tests for the data aggregation logic (e.g., averaging raw samples into 5-minute intervals).
- [ ] T014 [US2] Write an integration test to verify that data saved by the agent can be fetched correctly by the UI for a given time range.

### Implementation for User Story 2

- [x] T015 [US2] Expand the agent's data collection in `NetworkMonitorAgent.swift` to also measure jitter and packet loss.
- [ ] T016 [US2] Implement the data aggregation logic to create 5-minute and 1-hour summary data points.
- [ ] T017 [US2] [P] Enhance the XPC protocol to allow the UI to request historical data by time range.
- [ ] T018 [US2] In the UI, add controls (e.g., a `DatePicker`) to allow users to select a time range.
- [ ] T019 [US2] Update `ContentView.swift` and related views to display separate charts for latency, jitter, and packet loss, populated with data from the XPC service based on the selected time range.

**Checkpoint**: User Story 2 is functional. The UI can display historical charts for multiple metrics.

---

## Phase 4: User Story 3 - Proactive Notifications (Priority: P3)

**Goal**: As a user, I want to receive a system notification when my network quality degrades significantly so I can be proactively informed of issues.
**Independent Test**: When the agent measures latency above a configurable threshold, a macOS notification appears.

### Tests for User Story 3

- [ ] T020 [US3] Write a unit test for the logic that determines if a network sample breaches the defined quality threshold.

### Implementation for User Story 3

- [ ] T021 [US3] [P] Add a settings section to the UI to allow users to enable/disable notifications and set a latency threshold.
- [ ] T022 [US3] Pass the notification configuration from the UI to the agent via XPC.
- [ ] T023 [US3] In `NetworkMonitorAgent.swift`, implement logic to check each new sample against the threshold.
- [ ] T024 [US3] If the threshold is breached, use `UNUserNotificationCenter` from within the agent to post a system notification.

**Checkpoint**: User Story 3 is functional. The app can send alerts based on network conditions.

---

## Phase 5: Polish & Cross-Cutting Concerns

- [ ] T025 [P] Implement the `NSStatusItem` (menu bar icon) for quick access to the app status.
- [ ] T026 [P] Add documentation to the public-facing methods in the XPC protocol.
- [ ] T027 Refine error handling for XPC communication and data collection.
- [ ] T028 Code cleanup and final UI polish based on user feedback.
