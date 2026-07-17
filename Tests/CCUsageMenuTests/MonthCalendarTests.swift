import XCTest
@testable import CCUsageMenu

final class MonthCalendarTests: XCTestCase {
    func testJuly2026AlignsToSundayFirstCalendar() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "Asia/Tokyo"))
        calendar.firstWeekday = 1
        let month = try XCTUnwrap(
            calendar.date(from: DateComponents(year: 2026, month: 7, day: 1))
        )

        let dates = MonthCalendar.dates(in: month, calendar: calendar)

        XCTAssertEqual(dates.count, 35)
        XCTAssertNil(dates[0])
        XCTAssertNil(dates[1])
        XCTAssertNil(dates[2])
        XCTAssertEqual(
            calendar.component(.day, from: try XCTUnwrap(dates[3])),
            1
        )
        XCTAssertEqual(
            calendar.component(.day, from: try XCTUnwrap(dates[33])),
            31
        )
        XCTAssertNil(dates[34])
    }
}
