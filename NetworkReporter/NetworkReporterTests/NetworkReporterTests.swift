//
//  NetworkReporterTests.swift
//  NetworkReporterTests
//
//  Created by Maurice Roach on 22/12/2025.
//

import Testing
@testable import NetworkReporter

struct NetworkReporterTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

    @Test func testISO8601TimestampFormat() {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let timestampString = dateFormatter.string(from: Date())

        // Regular expression to match ISO 8601 format: YYYY-MM-DDTHH:MM:SS.sssZ
        let iso8601Regex = #"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$"#
        #expect(timestampString.range(of: iso8601Regex, options: .regularExpression) != nil)
    }

}
