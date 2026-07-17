import Foundation

@MainActor
final class UsageViewModel: ObservableObject {
    @Published private(set) var snapshot: UsageSnapshot?
    @Published private(set) var isLoading = false
    @Published private(set) var loadError: Error?
    @Published private(set) var lastUpdated: Date?

    private let client: any UsageLoading

    init(
        client: any UsageLoading = CCUsageClient(),
        snapshot: UsageSnapshot? = nil,
        lastUpdated: Date? = nil
    ) {
        self.client = client
        self.snapshot = snapshot
        self.lastUpdated = lastUpdated
    }

    var menuBarTitle: String {
        guard let snapshot else { return "ccusage" }
        return CurrencyFormatters.menu.string(from: snapshot.today.totalCost as NSNumber) ?? "$0"
    }

    func load(force: Bool = false) async {
        if isLoading { return }
        if !force, let lastUpdated, Date().timeIntervalSince(lastUpdated) < 60 {
            return
        }

        isLoading = true
        loadError = nil
        defer { isLoading = false }

        let calendar = Calendar.current
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
            snapshot = UsageSnapshot.make(report: report, now: now, calendar: calendar)
            lastUpdated = Date()
        } catch {
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
