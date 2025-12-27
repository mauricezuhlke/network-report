# Research & Decisions for MVP XPC Connection

This document outlines the research and decisions made to resolve technical unknowns for the MVP XPC connection feature.

## 1. State Management in SwiftUI

**Decision**: Use the MVVM (Model-View-ViewModel) pattern with `ObservableObject`.

**Rationale**:
- Separates UI logic (`View`) from business logic (`ViewModel`), improving testability and maintainability.
- Integrates naturally with SwiftUI's state management system.
- A `ContentViewModel` will be created as an `@StateObject` in `ContentView`. It will manage the state (timestamp string, error message) and handle the logic for interacting with the XPC service.
- State changes will be communicated to the View via `@Published` properties.

**Alternatives Considered**:
- **Pure @State**: Managing state directly in the `View` with `@State` is suitable for simple, local UI state but becomes unwieldy for logic involving external services.
- **Redux-like Architectures**: Overkill for the simple scope of this feature.

## 2. Asynchronous Operations & Error Handling

**Decision**:
- Use Swift's modern `async/await` syntax for all asynchronous operations.
- The button action in `ContentView` will create a `Task` to call an `async` method on the ViewModel.
- The ViewModel method will call the XPC service. This method will be marked with `@MainActor` to ensure UI-bound `@Published` properties are updated safely on the main thread.
- The XPC protocol method will be defined as `async throws` to return either a `String` result or throw an `Error`.
- The ViewModel will use a `do-catch` block to handle errors thrown by the XPC service. The caught error's `localizedDescription` will be published to the UI for display.

**Rationale**:
- `async/await` dramatically simplifies asynchronous code, making it more readable and eliminating the "pyramid of doom" associated with completion handlers.
- Structured concurrency with `Task` provides a clear lifecycle for the operation and handles cancellation automatically.
- Using `throws` for error propagation is the standard, idiomatic way to handle errors in modern Swift.

**Alternatives Considered**:
- **Completion Handlers**: The traditional approach, but it is more verbose and error-prone than `async/await`. The XPC API itself uses completion handlers, so we will wrap it in an `async` call.

## 3. XPC Contract Design

**Decision**: The XPC protocol will define a single method using a traditional Objective-C compatible completion handler `(String?, Error?) -> Void`. This will then be wrapped by the client-side proxy to provide a modern `async throws -> String` interface for the ViewModel.

The protocol will be:
`func getTimestamp(with reply: @escaping (String?, Error?) -> Void)`

This Objective-C compatible completion handler will be wrapped in the client-side proxy to provide a clean `async throws -> String` interface for the ViewModel.

**Rationale**:
- `@objc` protocols, required for XPC communication, do not directly support Swift's `Result` type. A traditional `(value?, error?) -> Void` completion handler is the standard and compatible approach.
- The client-side wrapper will bridge this older pattern into modern `async/await` for the application layer.

**Alternatives Considered**:
- **Using `Result` in protocol**: Not compatible with `@objc` protocols, as demonstrated by build failure.
- **Direct `async` in protocol**: Can be complex to set up correctly with XPC's underlying Objective-C base and may not be as reliable as traditional completion handlers.
