import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case japanese
    case english

    var id: String { rawValue }

    func text(_ japanese: String, _ english: String) -> String {
        self == .japanese ? japanese : english
    }

    var locale: Locale {
        Locale(identifier: self == .japanese ? "ja_JP" : "en_US")
    }
}

enum MenuBarDisplay: String, CaseIterable, Identifiable {
    case none
    case cost
    case tokens

    var id: String { rawValue }
}

enum RefreshFrequency: String, CaseIterable, Identifiable {
    case manual
    case oneMinute
    case fiveMinutes
    case fifteenMinutes
    case thirtyMinutes
    case hourly

    var id: String { rawValue }

    var seconds: TimeInterval? {
        switch self {
        case .manual: nil
        case .oneMinute: 60
        case .fiveMinutes: 5 * 60
        case .fifteenMinutes: 15 * 60
        case .thirtyMinutes: 30 * 60
        case .hourly: 60 * 60
        }
    }
}

@MainActor
final class AppSettings: ObservableObject {
    @Published var language: AppLanguage {
        didSet { defaults.set(language.rawValue, forKey: Keys.language) }
    }

    @Published var menuBarDisplay: MenuBarDisplay {
        didSet { defaults.set(menuBarDisplay.rawValue, forKey: Keys.menuBarDisplay) }
    }

    @Published var refreshFrequency: RefreshFrequency {
        didSet { defaults.set(refreshFrequency.rawValue, forKey: Keys.refreshFrequency) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        language = AppLanguage(
            rawValue: defaults.string(forKey: Keys.language) ?? ""
        ) ?? .japanese
        menuBarDisplay = MenuBarDisplay(
            rawValue: defaults.string(forKey: Keys.menuBarDisplay) ?? ""
        ) ?? .none
        refreshFrequency = RefreshFrequency(
            rawValue: defaults.string(forKey: Keys.refreshFrequency) ?? ""
        ) ?? .fiveMinutes
    }

    private enum Keys {
        static let language = "settings.language"
        static let menuBarDisplay = "settings.menuBarDisplay"
        static let refreshFrequency = "settings.refreshFrequency"
    }
}
