# Tasks: MVP XPC Connection Test

**Input**: Design documents from `specs/updated-xpc/`
**Prerequisites**: plan.md, BuildStory.md (spec), research.md, data-model.md, contracts/

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1)
- Include exact file paths in descriptions

---
## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Ensure the project is in a runnable state before changes.

- [X] T001 Verify `NetworkReporter.xcodeproj` builds and runs successfully.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Create the foundational classes for the MVVM pattern and XPC client communication.

- [X] T002 Create the ViewModel file in `NetworkReporter/NetworkReporter/ContentViewModel.swift`
- [X] T003 Create the XPC client wrapper in `NetworkReporter/NetworkReporter/XPCClient.swift`

**Checkpoint**: Foundation ready - user story implementation can now begin.

---

## Phase 3: User Story 1 - MVP XPC Connection (Priority: P1) 🎯 MVP

**Goal**: As a user, I can press a button to get a timestamp from the XPC service, see the timestamp on success, or see an error message on failure.

**Independent Test**: Run the app. Click the "Get Timestamp" button. A valid ISO 8601 timestamp appears. Stop the `NetworkReporterService` process and click the button again. An error message appears.

### Implementation for User Story 1

- [X] T004 [US1] In `NetworkReporter/NetworkReporter/ContentViewModel.swift`, define `@Published` properties for the result string and any potential error message.
- [X] T005 [US1] In `NetworkReporter/NetworkReporter/XPCClient.swift`, implement the logic to establish and manage the `NSXPCConnection` to the service.
- [X] T006 [US1] In `NetworkReporter/NetworkReporter/XPCClient.swift`, implement a public `getTimestamp() async throws -> String` method that wraps the XPC proxy call, bridging the `(String?, Error?) -> Void` completion handler to `async/await`.
- [X] T007 [US1] In `NetworkReporter/NetworkReporter/ContentViewModel.swift`, implement a `fetchTimestamp()` method that calls the `XPCClient` and updates the `@Published` properties from a `do-catch` block.
- [X] T008 [US1] In `NetworkReporter/NetworkReporter/ContentView.swift`, add a `@StateObject` to instantiate the `ContentViewModel`.
- [X] T009 [US1] In `NetworkReporter/NetworkReporter/ContentView.swift`, implement a `Button` that calls the ViewModel's `fetchTimestamp()` method and `Text` views to display the results.
- [X] T010 [P] [US1] In `NetworkReporter/NetworkReporterService/NetworkReporterService.swift`, implement the `getTimestamp` method to conform to the updated protocol, creating an ISO 8601 string and passing it to the `String?` parameter and `nil` to the `Error?` parameter of the reply.
- [X] T011 [US1] In `NetworkReporterTests/NetworkReporterTests.swift`, add a simple unit test to confirm the ISO 8601 timestamp formatting logic is correct.

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently.

---

## Phase 4: Polish & Cross-Cutting Concerns

**Purpose**: Final verification and cleanup.

- [X] T012 Run through all steps in `specs/updated-xpc/quickstart.md` to validate the final implementation.
- [X] T013 Review implemented code for clarity and add comments where necessary.

---

## Dependencies & Execution Order

- **Phase 1 (Setup)** must be completed first.
- **Phase 2 (Foundational)** depends on Phase 1.
- **Phase 3 (User Story 1)** depends on Phase 2.
- **Phase 4 (Polish)** depends on Phase 3.

### Within User Story 1

- **T010** (service implementation) can be done in parallel with client-side work (**T004-T009**).
- ViewModel work (**T004**, **T007**) and XPCClient work (**T005**, **T006**) should be done before the View is connected to them (**T008**, **T009**).

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1.  Complete Phase 1: Setup.
2.  Complete Phase 2: Foundational.
3.  Complete all tasks in Phase 3: User Story 1.
4.  **STOP and VALIDATE**: Test User Story 1 independently by following the `quickstart.md`.
5.  Complete Phase 4: Polish.
