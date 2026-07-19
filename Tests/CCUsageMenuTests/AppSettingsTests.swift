import XCTest
@testable import CCUsageMenu

@MainActor
final class AppSettingsTests: XCTestCase {
    func testSettingsPersistAcrossInstances() throws {
        let suiteName = "AppSettingsTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settings = AppSettings(defaults: defaults)
        settings.language = .english
        settings.menuBarDisplay = .tokens
        settings.refreshFrequency = .thirtyMinutes
        settings.aggregationTimeZone = .utc

        let restored = AppSettings(defaults: defaults)
        XCTAssertEqual(restored.language, .english)
        XCTAssertEqual(restored.menuBarDisplay, .tokens)
        XCTAssertEqual(restored.refreshFrequency, .thirtyMinutes)
        XCTAssertEqual(restored.aggregationTimeZone, .utc)
    }

    func testMenuCostAlwaysRoundsDown() {
        XCTAssertEqual(UsageFormatters.menuCost(85.99), "$85")
        XCTAssertEqual(UsageFormatters.menuCost(0.99), "$0")
    }

    func testRefreshFrequencyIntervals() {
        XCTAssertNil(RefreshFrequency.manual.seconds)
        XCTAssertEqual(RefreshFrequency.oneMinute.seconds, 60)
        XCTAssertEqual(RefreshFrequency.fiveMinutes.seconds, 300)
        XCTAssertEqual(RefreshFrequency.hourly.seconds, 3_600)
    }

    func testAggregationTimeZoneChangesDateAtJSTDayBoundary() throws {
        let formatter = ISO8601DateFormatter()
        let date = try XCTUnwrap(formatter.date(from: "2026-07-17T15:30:00Z"))

        XCTAssertEqual(
            DateFormatters.periodString(
                from: date,
                timeZone: AggregationTimeZone.jst.timeZone
            ),
            "2026-07-18"
        )
        XCTAssertEqual(
            DateFormatters.periodString(
                from: date,
                timeZone: AggregationTimeZone.utc.timeZone
            ),
            "2026-07-17"
        )
    }

    func testUTCUsesExpectedCCUsageCommandIdentifier() {
        XCTAssertEqual(
            CCUsageClient.commandIdentifier(
                for: AggregationTimeZone.utc.timeZone
            ),
            "UTC"
        )
        XCTAssertEqual(
            CCUsageClient.commandIdentifier(
                for: AggregationTimeZone.jst.timeZone
            ),
            "Asia/Tokyo"
        )
    }
}
