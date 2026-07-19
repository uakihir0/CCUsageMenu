import Foundation

struct UsageReport: Decodable, Sendable {
    let daily: [DailyUsage]
    let totals: UsageTotals
}

struct UsageTotals: Decodable, Sendable {
    let inputTokens: Int64
    let outputTokens: Int64
    let cacheCreationTokens: Int64
    let cacheReadTokens: Int64
    let totalTokens: Int64
    let totalCost: Double
}

struct DailyUsage: Decodable, Identifiable, Sendable {
    let period: String
    let inputTokens: Int64
    let outputTokens: Int64
    let cacheCreationTokens: Int64
    let cacheReadTokens: Int64
    let totalTokens: Int64
    let totalCost: Double
    let modelsUsed: [String]
    let modelBreakdowns: [ModelBreakdown]
    let metadata: UsageMetadata?

    var id: String { period }

    static func empty(period: String) -> DailyUsage {
        DailyUsage(
            period: period,
            inputTokens: 0,
            outputTokens: 0,
            cacheCreationTokens: 0,
            cacheReadTokens: 0,
            totalTokens: 0,
            totalCost: 0,
            modelsUsed: [],
            modelBreakdowns: [],
            metadata: nil
        )
    }
}

struct ModelBreakdown: Decodable, Identifiable, Sendable {
    let modelName: String
    let inputTokens: Int64
    let outputTokens: Int64
    let cacheCreationTokens: Int64
    let cacheReadTokens: Int64
    let cost: Double

    var id: String { modelName }
    var totalTokens: Int64 {
        inputTokens + outputTokens + cacheCreationTokens + cacheReadTokens
    }
}

struct UsageMetadata: Decodable, Sendable {
    let agents: [String]
}

struct UsageSnapshot: Sendable {
    let days: [DailyUsage]
    let todayKey: String

    var today: DailyUsage {
        days.first(where: { $0.period == todayKey }) ?? .empty(period: todayKey)
    }

    static func make(
        report: UsageReport,
        now: Date = Date(),
        calendar inputCalendar: Calendar = .current
    ) -> UsageSnapshot {
        let calendar = inputCalendar
        let formatter: DateFormatter = {
            let f = DateFormatter()
            f.calendar = calendar
            f.locale = Locale(identifier: "en_US_POSIX")
            f.dateFormat = "yyyy-MM-dd"
            f.timeZone = calendar.timeZone
            return f
        }()
        let startOfToday = calendar.startOfDay(for: now)
        let rowsByPeriod = Dictionary(
            report.daily.map { ($0.period, $0) },
            uniquingKeysWith: { _, latest in latest }
        )

        let days = (-6...0).compactMap { offset -> DailyUsage? in
            guard let date = calendar.date(byAdding: .day, value: offset, to: startOfToday) else {
                return nil
            }
            let key = formatter.string(from: date)
            return rowsByPeriod[key] ?? .empty(period: key)
        }

        return UsageSnapshot(
            days: days,
            todayKey: formatter.string(from: startOfToday)
        )
    }
}

enum DateFormatters {
    static func periodString(from date: Date, timeZone: TimeZone) -> String {
        periodFormatter(timeZone: timeZone).string(from: date)
    }

    static func date(fromPeriod period: String, timeZone: TimeZone) -> Date? {
        periodFormatter(timeZone: timeZone).date(from: period)
    }

    static func weekdayString(
        from date: Date,
        language: AppLanguage,
        timeZone: TimeZone
    ) -> String {
        formatter(
            locale: language.locale,
            dateFormat: language == .japanese ? "E" : "EEE",
            timeZone: timeZone
        ).string(from: date)
    }

    static func selectedDayString(
        from date: Date,
        language: AppLanguage,
        timeZone: TimeZone
    ) -> String {
        formatter(
            locale: language.locale,
            dateFormat: language == .japanese ? "M月d日（E）" : "MMM d (EEE)",
            timeZone: timeZone
        ).string(from: date)
    }

    private static func periodFormatter(timeZone: TimeZone) -> DateFormatter {
        formatter(
            locale: Locale(identifier: "en_US_POSIX"),
            dateFormat: "yyyy-MM-dd",
            timeZone: timeZone
        )
    }

    private static func formatter(
        locale: Locale,
        dateFormat: String,
        timeZone: TimeZone
    ) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = locale
        formatter.dateFormat = dateFormat
        formatter.timeZone = timeZone
        return formatter
    }

    static let period: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static let weekday: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "E"
        return formatter
    }()

    static let weekdayEnglish: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "EEE"
        return formatter
    }()

    static let updatedAt: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "H:mm"
        return formatter
    }()

    static let selectedDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日（E）"
        return formatter
    }()

    static let selectedDayEnglish: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMM d (EEE)"
        return formatter
    }()
}
