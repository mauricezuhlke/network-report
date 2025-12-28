# API Contracts for Network Performance Monitor

For this native MacOS Desktop application, the primary inter-process communication (IPC) contract is defined by the `NetworkReporterServiceProtocol.swift`. This protocol governs the communication between the main `NetworkReporter` application and its privileged background `NetworkReporterService` (XPC Service).

**No new external API endpoints or schemas (e.g., OpenAPI, GraphQL) are being introduced as part of this feature.** The feature focuses on enhancing data collection, storage, and presentation within the existing application architecture.

The relevant protocol can be found at: `NetworkReporter/NetworkReporterServiceProtocol.swift` (shared between targets).
