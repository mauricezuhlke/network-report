# Research for Network Performance Monitor

## Technology Choices and Rationale

**Decision**: Native MacOS Desktop application based on `NetworkReporter`
**Rationale**: Explicitly specified by the user as the foundation for the feature. This ensures integration with the existing project and adheres to the MacOS-only requirement.
**Alternatives considered**: Other cross-platform frameworks (e.g., Electron, Flutter) were implicitly rejected due to the "Native MacOS Desktop only" and "use the app build (NetworkReporter) as the foundation" constraints.

**Decision**: SQLite for historical data storage
**Rationale**: Explicitly specified by the user. SQLite is a lightweight, file-based database well-suited for single-user desktop applications and is often integrated via CoreData on MacOS.
**Alternatives considered**: Other database solutions (e.g., Realm, Firebase, custom file formats) were rejected due to the explicit SQLite constraint.

**Decision**: Native MacOS libraries and frameworks for graphs and charts
**Rationale**: Explicitly specified by the user ("native MacOS libraries and frameworks for graphs and charts. No external dependencies"). This ensures a consistent look and feel with the operating system and avoids introducing third-party dependencies.
**Alternatives considered**: Third-party charting libraries (e.g., Charts by Daniel Gindi, Plotly) were rejected due to the "No external dependencies" constraint. This implies a need to either leverage existing native charting capabilities (if available in SwiftUI/AppKit) or implement custom charting using Core Graphics/Core Animation.

**Decision**: No external third-party dependencies
**Rationale**: Explicitly specified by the user ("No external dependencies - only core OS frameworks, libraries or plugins"). This simplifies project management, reduces potential security vulnerabilities, and ensures adherence to a pure native MacOS ecosystem.
**Alternatives considered**: Utilizing popular Swift package manager libraries or CocoaPods was rejected due to this strict constraint.
