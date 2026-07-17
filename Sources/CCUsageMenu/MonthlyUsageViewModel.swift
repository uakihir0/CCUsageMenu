import Foundation

@MainActor
final class MonthlyUsageViewModel: ObservableObject {
    @Published private(set) var selectedMonth: Date
    @Published private(set) var days: [DailyUsage] = []
    @Published private(set) var isLoading = false
    @Published private(set) var loadError: Error?

    private let client: any UsageLoading
    private var calendar: Calendar
    private var cache: [String: [DailyUsage]] = [:]

    init(
        client: any UsageLoading = CCUsageClient(),
        calendar: Calendar = .current,
        now: Date = Date()
    ) {
        self.client = client
        self.calendar = calendar
        selectedMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
    }

    var totalCost: Double {
        days.reduce(0) { $0 + $1.totalCost }
    }

    var totalTokens: Int64 {
        days.reduce(0) { $0 + $1.totalTokens }
    }

    var canMoveForward: Bool {
        guard let currentMonth = calendar.dateInterval(of: .month, for: Date())?.start else {
            return false
        }
        return selectedMonth < currentMonth
    }

    func load(force: Bool = false) async {
        if isLoading { return }

        let key = DateFormatters.period.string(from: selectedMonth)
        if !force, let cached = cache[key] {
            days = cached
            loadError = nil
            return
        }

        guard let interval = calendar.dateInterval(of: .month, for: selectedMonth),
              let lastDay = calendar.date(byAdding: .day, value: -1, to: interval.end) else {
            return
        }

        let today = calendar.startOfDay(for: Date())
        let end = min(lastDay, today)
        guard interval.start <= end else {
            days = []
            return
        }

        isLoading = true
        loadError = nil
        defer { isLoading = false }

        do {
            let report = try await client.load(
                from: interval.start,
                through: end,
                timeZone: calendar.timeZone
            )
            cache[key] = report.daily
            days = report.daily
        } catch {
            loadError = error
        }
    }

    func moveMonth(by offset: Int) async {
        guard let target = calendar.date(
            byAdding: .month,
            value: offset,
            to: selectedMonth
        ) else {
            return
        }

        if offset > 0,
           let currentMonth = calendar.dateInterval(of: .month, for: Date())?.start,
           target > currentMonth {
            return
        }

        selectedMonth = target
        days = []
        loadError = nil
        await load()
    }
}

enum MonthCalendar {
    static func dates(
        in month: Date,
        calendar inputCalendar: Calendar = .current
    ) -> [Date?] {
        let calendar = inputCalendar
        guard let interval = calendar.dateInterval(of: .month, for: month),
              let dayRange = calendar.range(of: .day, in: .month, for: month) else {
            return []
        }

        let weekday = calendar.component(.weekday, from: interval.start)
        let leadingCount = (weekday - calendar.firstWeekday + 7) % 7
        var dates = Array<Date?>(repeating: nil, count: leadingCount)

        dates.append(contentsOf: dayRange.compactMap { day in
            calendar.date(bySetting: .day, value: day, of: interval.start)
        })

        let trailingCount = (7 - dates.count % 7) % 7
        dates.append(contentsOf: Array<Date?>(repeating: nil, count: trailingCount))
        return dates
    }
}
