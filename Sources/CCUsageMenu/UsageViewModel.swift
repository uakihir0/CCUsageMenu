import Foundation

@MainActor
final class UsageViewModel: ObservableObject {
    @Published private(set) var snapshot: UsageSnapshot?
    @Published private(set) var isLoading = false
    @Published private(set) var loadError: Error?
    @Published private(set) var lastUpdated: Date?

    private let client: any UsageLoading
    private(set) var aggregationTimeZone: AggregationTimeZone
    private var loadGeneration = 0

    init(
        client: any UsageLoading = CCUsageClient(),
        snapshot: UsageSnapshot? = nil,
        lastUpdated: Date? = nil,
        aggregationTimeZone: AggregationTimeZone = .jst
    ) {
        self.client = client
        self.snapshot = snapshot
        self.lastUpdated = lastUpdated
        self.aggregationTimeZone = aggregationTimeZone
    }

    var menuBarTitle: String {
        guard let snapshot else { return "ccusage" }
        return CurrencyFormatters.menu.string(from: snapshot.today.totalCost as NSNumber) ?? "$0"
    }

    func load(force: Bool = false) async {
        await load(force: force, supersedingCurrentLoad: false)
    }

    func setAggregationTimeZone(_ timeZone: AggregationTimeZone) async {
        guard aggregationTimeZone != timeZone else { return }
        aggregationTimeZone = timeZone
        snapshot = nil
        lastUpdated = nil
        await load(force: true, supersedingCurrentLoad: true)
    }

    private func load(
        force: Bool,
        supersedingCurrentLoad: Bool
    ) async {
        if isLoading, !supersedingCurrentLoad { return }
        if !force, let lastUpdated, Date().timeIntervalSince(lastUpdated) < 60 {
            return
        }

        loadGeneration += 1
        let generation = loadGeneration
        isLoading = true
        loadError = nil
        defer {
            if generation == loadGeneration {
                isLoading = false
            }
        }

        let calendar = aggregationTimeZone.calendar
        let now = Date()
        let end = calendar.startOfDay(for: now)
        guard let start = calendar.date(byAdding: .day, value: -6, to: end) else {
            return
        }

        do {
            let report = try await client.load(
                from: start,
                through: end,
                timeZone: calendar.timeZone
            )
            guard generation == loadGeneration else { return }
            snapshot = UsageSnapshot.make(report: report, now: now, calendar: calendar)
            lastUpdated = Date()
        } catch {
            guard generation == loadGeneration else { return }
            loadError = error
        }
    }
}

enum CurrencyFormatters {
    static let full: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()

    static let menu: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()
}

enum UsageFormatters {
    static let tokens: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    static func compactTokens(_ value: Int64) -> String {
        let absolute = abs(Double(value))
        let divisor: Double
        let suffix: String

        switch absolute {
        case 1_000_000_000...:
            divisor = 1_000_000_000
            suffix = "B"
        case 1_000_000...:
            divisor = 1_000_000
            suffix = "M"
        case 1_000...:
            divisor = 1_000
            suffix = "K"
        default:
            return NumberFormatter.localizedString(from: value as NSNumber, number: .decimal)
        }

        let number = tokens.string(from: NSNumber(value: Double(value) / divisor)) ?? "0"
        return "\(number)\(suffix)"
    }

    static func cost(_ value: Double) -> String {
        CurrencyFormatters.full.string(from: value as NSNumber) ?? "$0.00"
    }

    static func menuCost(_ value: Double) -> String {
        let wholeCost = Int(floor(max(0, value)))
        let amount = NumberFormatter.localizedString(
            from: wholeCost as NSNumber,
            number: .decimal
        )
        return "$\(amount)"
    }
}
