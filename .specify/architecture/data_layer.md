# Data Layer Implementation (SQLite with Core Data)

## 1. Overview

This section details the implementation of the data layer for the Speckit Network Monitor. We will use Core Data, Apple's powerful framework for managing object graphs, with SQLite as its persistent store. This approach leverages native macOS capabilities for efficient and robust data management, while allowing for complex data modeling and querying.

## 2. Core Data Stack

The Core Data stack will consist of the following components:

*   **Managed Object Model (SpeckitNetworkMonitor.xcdatamodeld)**: Defines the entities, attributes, and relationships of our data. This will be created graphically in Xcode.
*   **Persistent Container (NSPersistentContainer)**: Manages the Core Data stack, including the managed object model, persistent store coordinator, and managed object contexts.
*   **Managed Object Contexts (NSManagedObjectContext)**: Used for interacting with the managed objects. We will use a main context for UI operations and potentially background contexts for agent data saving and aggregation to avoid blocking the main thread.

## 3. Database Schema (Entities and Attributes)

We will define two primary entities within our `SpeckitNetworkMonitor.xcdatamodeld`:

### 3.1. `NetworkSample` Entity

This entity will store individual, raw network performance measurements. It directly corresponds to the `Sample` entity described in `speckit.specify`.

*   **Attributes**:
    *   `timestampUTC`: `Date` (Non-optional, Indexed) - The exact UTC time when the sample was taken.
    *   `latencyAvgMs`: `Double` (Non-optional) - Average latency in milliseconds.
    *   `latencyMinMs`: `Double` (Non-optional) - Minimum latency in milliseconds.
    *   `latencyMaxMs`: `Double` (Non-optional) - Maximum latency in milliseconds.
    *   `packetLossPct`: `Double` (Non-optional) - Percentage of packet loss (0.0 to 1.0).
    *   `jitterMs`: `Double` (Non-optional) - Jitter in milliseconds (standard deviation of latency).
    *   `uploadBpsEst`: `Double` (Optional) - Estimated upload throughput in bits per second.
    *   `downloadBpsEst`: `Double` (Optional) - Estimated download throughput in bits per second.
    *   `interfaceID`: `String` (Optional) - Identifier for the network interface used (e.g., "en0", "Wi-Fi").
    *   `sampleMethod`: `String` (Non-optional) - Method used for sampling (e.g., "ICMP", "TCP").
    *   `confidence`: `Double` (Non-optional) - Confidence score for the sample (0.0 to 1.0).

### 3.2. `AggregatedSeries` Entity

This entity will store aggregated network performance data over defined intervals, optimizing for long-term storage and historical chart rendering. It corresponds to the `Series` entity described in `speckit.specify`.

*   **Attributes**:
    *   `timestampStartUTC`: `Date` (Non-optional, Indexed) - The UTC start time of the aggregation interval.
    *   `timestampEndUTC`: `Date` (Non-optional) - The UTC end time of the aggregation interval.
    *   `intervalType`: `String` (Non-optional) - Type of aggregation interval (e.g., "5m", "1h", "1d").
    *   `metricType`: `String` (Non-optional) - Type of metric aggregated (e.g., "latency", "packet_loss", "throughput").
    *   `valueAvg`: `Double` (Non-optional) - Average value for the aggregated metric.
    *   `valueMin`: `Double` (Non-optional) - Minimum value for the aggregated metric.
    *   `valueMax`: `Double` (Non-optional) - Maximum value for the aggregated metric.
    *   `interfaceID`: `String` (Optional) - Identifier for the network interface, if aggregation is specific to an interface.

## 4. Data Access Layer (DAL) Design

The DAL will provide a clear, testable interface for the Background Agent and Main Application to interact with the Core Data store, abstracting away the underlying Core Data implementation details.

*   **`CoreDataStackManager`**: A singleton class responsible for initializing and managing the `NSPersistentContainer`, providing access to the main `NSManagedObjectContext` and allowing creation of background contexts.
*   **`NetworkDataStore` Protocol**: Defines methods for saving raw samples, fetching historical data, and performing aggregation operations.
*   **`CoreDataNetworkDataStore` Class**: Conforms to `NetworkDataStore` and implements the Core Data specific logic for CRUD operations.

### 4.1. Key Operations

*   **Save Raw Samples**: The Background Agent will use the `CoreDataNetworkDataStore` to save `NetworkSample` objects. This should happen on a background `NSManagedObjectContext` to avoid UI blocking.
*   **Fetch Historical Data**: The UI will query the `CoreDataNetworkDataStore` to retrieve `NetworkSample` or `AggregatedSeries` objects for specific time ranges and aggregation levels. Fetches will use `NSFetchRequest` with predicates and sort descriptors.
*   **Data Aggregation & Down-sampling**: The Background Agent (or a dedicated Core Data operation) will periodically aggregate raw `NetworkSample` data into `AggregatedSeries` entries for longer time periods. This process will also handle deleting older raw samples based on the retention policy (`NFR-003`).

## 5. Persistent Store Location and Configuration

*   The SQLite database file will be stored in the application's sandboxed `Application Support` directory, ensuring proper macOS security and user data isolation.
*   Core Data's migration capabilities will be leveraged for schema changes to ensure data persistence across app updates.

## 6. Security Considerations

*   **Data Protection**: As per `SEC-002`, if the local data is deemed sensitive, Core Data's persistent store can be configured with file protection (`NSFileProtectionComplete` or `NSFileProtectionCompleteUnlessOpen`). `Keychain Services` may be used for encryption keys if custom encryption is implemented for specific attributes.
*   **Sandbox**: Core Data operates within the app's sandbox. Access to the database file is restricted to the application itself.

