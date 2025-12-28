# Data Model: Network Performance Monitor

## Entity: NetworkPerformanceRecord

**Description**: Represents a single snapshot of network performance metrics at a specific point in time. This entity will be persisted using CoreData, backed by SQLite.

**Attributes**:

-   **id**: UUID (Primary Key, unique identifier for each record)
    -   **Type**: `UUID`
    -   **Description**: Unique identifier for the record.
-   **timestamp**: Date and time when the performance data was recorded.
    -   **Type**: `Date`
    -   **Description**: Crucial for historical analysis and ordering.
-   **latency**: The round-trip time in milliseconds to a designated ISP host.
    -   **Type**: `Double` (or `Int` if always whole milliseconds)
    -   **Description**: Measured in milliseconds.
-   **packetLoss**: The percentage of packets lost during the monitoring interval.
    -   **Type**: `Double` (0.0 to 1.0 representing 0% to 100%)
    -   **Description**: Percentage of data packets that failed to reach their destination.
-   **connectivityStatus**: The overall status of the network connection.
    -   **Type**: `Int16` (enum representation: e.g., 0 for Connected, 1 for Degraded, 2 for Disconnected)
    -   **Description**: Indicates the health of the connection.
-   **uploadSpeed**: The measured upload bandwidth.
    -   **Type**: `Double`
    -   **Description**: Measured in Megabits per second (Mbps).
-   **downloadSpeed**: The measured download bandwidth.
    -   **Type**: `Double`
    -   **Description**: Measured in Megabits per second (Mbps).

**Relationships**: (None for this entity in isolation)

**Validation Rules**:

-   `timestamp` MUST be recorded at the time of monitoring.
-   `packetLoss` MUST be between 0.0 and 1.0 (inclusive).
-   `latency`, `uploadSpeed`, `downloadSpeed` MUST be non-negative.
-   `connectivityStatus` MUST correspond to defined enum values.

**Persistence**:

-   This entity will be managed by CoreData.
-   The underlying storage will be SQLite, as per user requirement.
-   Data will be retained for 18 months, after which older records should be purged.
