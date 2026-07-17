import Foundation
import XCTest
@testable import CCUsageMenu

final class UsageReportTests: XCTestCase {
    func testDecodesCCUsageDailyJSON() throws {
        let data = Data(sampleJSON.utf8)
        let report = try JSONDecoder().decode(UsageReport.self, from: data)

        XCTAssertEqual(report.daily.count, 1)
        XCTAssertEqual(report.daily[0].period, "2026-07-17")
        XCTAssertEqual(report.daily[0].totalTokens, 65_538_046)
        XCTAssertEqual(report.daily[0].modelBreakdowns[0].modelName, "openai.gpt-5.6-sol")
        XCTAssertEqual(report.totals.totalCost, 85.076266, accuracy: 0.000001)
    }

    func testSnapshotFillsMissingDaysWithZeroUsage() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "Asia/Tokyo"))
        let now = try XCTUnwrap(DateFormatters.period.date(from: "2026-07-17"))
        let report = try JSONDecoder().decode(UsageReport.self, from: Data(sampleJSON.utf8))

        let snapshot = UsageSnapshot.make(report: report, now: now, calendar: calendar)

        XCTAssertEqual(snapshot.days.count, 7)
        XCTAssertEqual(snapshot.days.first?.period, "2026-07-11")
        XCTAssertEqual(snapshot.days.first?.totalTokens, 0)
        XCTAssertEqual(snapshot.today.totalTokens, 65_538_046)
    }

    private let sampleJSON = """
    {
      "daily": [{
        "agent": "all",
        "cacheCreationTokens": 455540,
        "cacheReadTokens": 56651015,
        "inputTokens": 8133215,
        "metadata": { "agents": ["claude", "codex"] },
        "modelBreakdowns": [{
          "cacheCreationTokens": 0,
          "cacheReadTokens": 33721161,
          "cost": 65.464365,
          "inputTokens": 7311333,
          "modelName": "openai.gpt-5.6-sol",
          "outputTokens": 157030
        }],
        "modelsUsed": ["openai.gpt-5.6-sol"],
        "outputTokens": 298276,
        "period": "2026-07-17",
        "totalCost": 85.076266,
        "totalTokens": 65538046
      }],
      "totals": {
        "cacheCreationTokens": 455540,
        "cacheReadTokens": 56651015,
        "inputTokens": 8133215,
        "outputTokens": 298276,
        "totalCost": 85.076266,
        "totalTokens": 65538046
      }
    }
    """
}
