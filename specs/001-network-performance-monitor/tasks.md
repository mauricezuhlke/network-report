---

description: "Task list for Network Performance Monitor feature implementation"
---

# Tasks: Network Performance Monitor

**Input**: Design documents from `/specs/001-network-performance-monitor/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/, quickstart.md

**Tests**: The examples below include test tasks. Tests are OPTIONAL - only include them if explicitly requested in the feature specification.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- Paths shown below assume the existing `NetworkReporter` project structure.

## Phase 1: Foundational (Blocking Prerequisites)

**Goal**: Establish data persistence via CoreData/SQLite and enhance the XPC service for comprehensive data collection.

**Independent Test**: The XPC service can successfully collect and store `NetworkPerformanceRecord` instances, and the main app can retrieve these records from the persistent store.

- [X] T001 Define `NetworkPerformanceRecord` CoreData Entity in `NetworkReporter/NetworkReporter.xcdatamodeld/NetworkReporter.xcdatamodel/contents`
- [X] T002 Implement CoreData stack setup and `NSPersistentContainer` in `NetworkReporter/NetworkReporter/Persistence.swift`
- [X] T003 [P] Create a helper class/extension for `NetworkPerformanceRecord` in `NetworkReporter/NetworkReporter/Models/NetworkPerformanceRecord+CoreData.swift`
- [X] T004 [P] Update `NetworkReporterServiceProtocol.swift` to include methods for saving `NetworkPerformanceRecord` and fetching historical data
- [X] T005 [P] Implement `NetworkReporterService` changes to collect `UploadSpeed` and `DownloadSpeed` metrics in `NetworkReporter/NetworkReporterService/NetworkReporterService.swift`
- [X] T006 Implement `NetworkReporterService` to send `NetworkPerformanceRecord` data to main app via XPC in `NetworkReporter/NetworkReporterService/NetworkReporterService.swift`
- [X] T007 Implement XPC client in `NetworkReporter/NetworkReporter/XPCClient.swift` to receive and save `NetworkPerformanceRecord` to CoreData
- [X] T008 Implement data purging logic to enforce 18-month retention in `NetworkReporter/NetworkReporter/Persistence.swift`
- [X] T009 Implement graceful monitoring pause/resume on application close/system shutdown events in `NetworkReporter/NetworkReporterService/NetworkReporterService.swift` and `NetworkReporter/NetworkReporterApp.swift`

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 2: User Story 1 - View Real-Time Network Status (Priority: P1) 🎯 MVP

**Goal**: Display current network connectivity status, latency, packet loss, upload, and download speeds.

**Independent Test**: Launch the application; observe the current network metrics displayed accurately on the main screen.

### Implementation for User Story 1

- [X] T010 [US1] Create `RealTimeNetworkView.swift` in `NetworkReporter/NetworkReporter/Views/RealTimeNetworkView.swift` to display real-time metrics
- [X] T011 [US1] Update `ContentViewModel.swift` to fetch and expose real-time metrics from `XPCClient`
- [X] T012 [US1] Integrate `RealTimeNetworkView` into `ContentView.swift`

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 3: User Story 2 - Analyze Historical Network Performance (Priority: P1)

**Goal**: Allow users to view historical network performance data through charts and graphs.

**Independent Test**: Navigate to the historical view; charts/graphs accurately reflect past performance data for selected time ranges.

### Implementation for User Story 2

- [X] T013 [US2] Create `HistoricalDataView.swift` in `NetworkReporter/NetworkReporter/Views/HistoricalDataView.swift` to contain historical charts
- [X] T014 [US2] Create `NetworkChartViewModel.swift` in `NetworkReporter/NetworkReporter/ViewModels/NetworkChartViewModel.swift` to manage chart data and time ranges
- [X] T015 [P] [US2] Implement charting components for Latency in `NetworkReporter/NetworkReporter/Views/Charts/LatencyChart.swift`
- [X] T016 [P] [US2] Implement charting components for Packet Loss in `NetworkReporter/NetworkReporter/Views/Charts/PacketLossChart.swift`
- [X] T017 [P] [US2] Implement charting components for Connectivity Status in `NetworkReporter/NetworkReporter/Views/Charts/ConnectivityChart.swift`
- [X] T018 [P] [US2] Implement charting components for Upload/Download Speed in `NetworkReporter/NetworkReporter/Views/Charts/SpeedChart.swift`
- [X] T019 [US2] Update `HistoricalDataView.swift` to integrate charting components and time range selection
- [X] T020 [US2] Update `ContentViewModel.swift` or create new `HistoricalViewModel.swift` to fetch historical `NetworkPerformanceRecord` data from CoreData

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Phase 4: User Story 3 - Identify Network Degradation Events (Priority: P2)

**Goal**: Visually highlight periods of significant network degradation on historical charts.

**Independent Test**: Simulate network degradation; observe charts visually emphasize these events (e.g., color changes, markers).

### Implementation for User Story 3

- [X] T021 [US3] Update `NetworkChartViewModel.swift` to include logic for identifying and marking degradation periods based on defined thresholds (Latency > 200ms, Packet Loss > 5%, Disconnection)
- [X] T022 [US3] Enhance charting components (`LatencyChart.swift`, `PacketLossChart.swift`, `ConnectivityChart.swift`, `SpeedChart.swift`) to visually highlight degradation

**Checkpoint**: All user stories should now be independently functional

---

## Phase 5: Polish & Cross-Cutting Concerns

**Goal**: Refine the feature, ensure robustness, and address non-functional requirements.

**Independent Test**: Full regression testing, performance monitoring, and user acceptance testing.

- [X] T023 Implement comprehensive error handling for network monitoring and data persistence in `NetworkReporter/NetworkReporterService/NetworkReporterService.swift` and `NetworkReporter/NetworkReporter/XPCClient.swift`
- [X] T024 Optimize CoreData queries for historical data retrieval in `NetworkReporter/NetworkReporter/Persistence.swift`
- [X] T025 Review and refine UI/UX for charts and real-time display in `NetworkReporter/NetworkReporter/Views/`
- [X] T026 Add unit tests for CoreData persistence logic in `NetworkReporterTests/NetworkReporterTests.swift`
- [X] T027 Add unit tests for network metric collection in `NetworkReporterTests/NetworkReporterTests.swift`
- [X] T028 Conduct end-to-end integration testing for data flow from service to UI
- [X] T029 Update `quickstart.md` with any new developer setup details
- [X] T030 Implement graceful handling for internet connection unavailability (pause/resume data collection, user feedback) in `NetworkReporter/NetworkReporterService/NetworkReporterService.swift` and `NetworkReporter/NetworkReporter/XPCClient.swift`

---

## Dependencies & Execution Order

### Phase Dependencies

-   **Foundational (Phase 1)**: No dependencies - can start immediately. BLOCKS all user stories.
-   **User Story 1 (Phase 2)**: Depends on Foundational (Phase 1) completion.
-   **User Story 2 (Phase 3)**: Depends on Foundational (Phase 1) completion. Can proceed in parallel with User Story 1 if desired.
-   **User Story 3 (Phase 4)**: Depends on Foundational (Phase 1) completion. Can proceed in parallel with User Story 1 and 2 if desired.
-   **Polish (Phase 5)**: Depends on all user stories (Phase 2, 3, 4) being largely complete.

### User Story Dependencies

-   **User Story 1 (P1)**: Can start after Foundational (Phase 1). No direct dependencies on other user stories for its core functionality.
-   **User Story 2 (P1)**: Can start after Foundational (Phase 1). Builds upon data collected in Foundational, but does not strictly depend on US1's UI.
-   **User Story 3 (P2)**: Can start after Foundational (Phase 1) and ideally after US2's basic charting is in place, as it enhances existing charts.

### Within Each User Story

-   Models/Entities (if created within a story) should be implemented before services that use them.
-   Services should be implemented before UI components that consume them.
-   Core implementation before integration.
-   Story complete before moving to the next priority, or for integration with other stories.

### Parallel Opportunities

-   All tasks within the Foundational Phase marked [P] can run in parallel.
-   Charting components (T015-T018) within User Story 2 can be developed in parallel.
-   Once the Foundational Phase completes, User Story 1, 2, and 3 can be worked on in parallel by different team members, although US3 benefits from US2's charting foundation.

---

## Parallel Example: User Story 2 Charting Components

```bash
# Developers can work on different chart types in parallel:
- [P] T015 [US2] Implement charting components for Latency in `NetworkReporter/NetworkReporter/Views/Charts/LatencyChart.swift`
- [P] T016 [US2] Implement charting components for Packet Loss in `NetworkReporter/NetworkReporter/Views/Charts/PacketLossChart.swift`
- [P] T017 [US2] Implement charting components for Connectivity Status in `NetworkReporter/NetworkReporter/Views/Charts/ConnectivityChart.swift`
- [P] T018 [US2] Implement charting components for Upload/Download Speed in `NetworkReporter/NetworkReporter/Views/Charts/SpeedChart.swift`
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1.  Complete Phase 1: Foundational
2.  Complete Phase 2: User Story 1
3.  **STOP and VALIDATE**: Test User Story 1 independently.
4.  Deploy/demo if ready.

### Incremental Delivery

1.  Complete Foundational (Phase 1) → Foundation ready.
2.  Add User Story 1 (Phase 2) → Test independently → Deploy/Demo (MVP!).
3.  Add User Story 2 (Phase 3) → Test independently → Deploy/Demo.
4.  Add User Story 3 (Phase 4) → Test independently → Deploy/Demo.
5.  Each story adds value without breaking previous stories.

### Parallel Team Strategy

With multiple developers:

1.  Team completes Foundational (Phase 1) together.
2.  Once Foundational is done:
    -   Developer A: User Story 1 (Phase 2)
    -   Developer B: User Story 2 (Phase 3)
    -   Developer C: User Story 3 (Phase 4)
3.  Stories complete and integrate independently.

---

## Notes

-   [P] tasks = different files, no dependencies
-   [Story] label maps task to specific user story for traceability
-   Each user story should be independently completable and testable
-   Commit after each task or logical group
-   Stop at any checkpoint to validate story independently
-   Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence