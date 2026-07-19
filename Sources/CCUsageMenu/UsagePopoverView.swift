import Charts
import SwiftUI

struct UsagePopoverView: View {
    @ObservedObject var viewModel: UsageViewModel
    @ObservedObject var settings: AppSettings
    let screenshotMode: Bool
    @StateObject private var monthlyViewModel: MonthlyUsageViewModel
    @State private var chartMetric: ChartMetric = .cost
    @State private var selectedPeriod: String?
    @State private var chartSelection: String?
    @State private var page: PopoverPage = .usage

    private var language: AppLanguage { settings.language }

    init(
        viewModel: UsageViewModel,
        settings: AppSettings,
        screenshotMode: Bool = false
    ) {
        self.viewModel = viewModel
        self.settings = settings
        self.screenshotMode = screenshotMode
        _monthlyViewModel = StateObject(
            wrappedValue: MonthlyUsageViewModel(
                aggregationTimeZone: settings.aggregationTimeZone
            )
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            switch page {
            case .settings:
                SettingsView(settings: settings)
            case .calendar:
                MonthlyCalendarView(
                    viewModel: monthlyViewModel,
                    settings: settings
                )
            case .usage:
                usageContent
                Divider()
                footer
            }
        }
        .frame(width: 320, height: 620)
        .task {
            await viewModel.load()
        }
        .onChange(of: viewModel.snapshot?.todayKey) { _, todayKey in
            if selectedPeriod == nil {
                selectedPeriod = todayKey
                chartSelection = todayKey
            }
        }
        .onChange(of: chartSelection) { _, period in
            if let period {
                selectedPeriod = period
            }
        }
        .onChange(of: settings.aggregationTimeZone) { _, timeZone in
            selectedPeriod = nil
            chartSelection = nil
            Task {
                await viewModel.setAggregationTimeZone(timeZone)
            }
            Task {
                await monthlyViewModel.setAggregationTimeZone(timeZone)
            }
        }
    }

    @ViewBuilder
    private var usageContent: some View {
        if screenshotMode {
            usageStack
                .frame(width: 320, height: 540, alignment: .topLeading)
                .clipped()
        } else {
            ScrollView {
                usageStack
            }
            .scrollIndicators(.hidden)
        }
    }

    private var usageStack: some View {
        VStack(alignment: .leading, spacing: 15) {
            if let error = viewModel.loadError {
                errorView(errorMessage(for: error))
            }

            if let snapshot = viewModel.snapshot {
                let selectedDay = selectedUsage(in: snapshot)
                usageSummary(selectedDay, todayKey: snapshot.todayKey)
                weeklyChart(snapshot.days, todayKey: snapshot.todayKey)
                DailyUsageDetails(day: selectedDay, language: language)
            } else if viewModel.isLoading {
                loadingView
            } else {
                emptyView
            }
        }
        .padding(14)
    }

    private var header: some View {
        HStack(spacing: 8) {
            if page != .usage {
                Button {
                    page = .usage
                } label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.borderless)
                .help(language.text("戻る", "Back"))

                Text(page == .settings
                    ? language.text("設定", "Settings")
                    : language.text("月間", "Monthly"))
                    .font(.headline)
            } else {
                CCUsageLogoView(size: 22)
                Text("ccusage")
                    .font(.headline)
            }

            Spacer()

            if page == .usage {
                if viewModel.isLoading {
                    ProgressView()
                        .controlSize(.small)
                }

                Button {
                    Task { await viewModel.load(force: true) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .help(language.text("使用量を更新", "Refresh usage"))

                Button {
                    page = .settings
                } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.borderless)
                .help(language.text("設定", "Settings"))
            } else if page == .calendar {
                Button {
                    Task { await monthlyViewModel.load(force: true) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .help(language.text("月間データを更新", "Refresh monthly usage"))
            }

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Image(systemName: "power")
            }
            .buttonStyle(.borderless)
            .help(language.text("ccusage を終了", "Quit ccusage"))
        }
        .padding(.horizontal, 14)
        .frame(height: 46)
    }

    private func usageSummary(_ day: DailyUsage, todayKey: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle(
                day.period == todayKey
                    ? language.text("今日", "Today")
                    : selectedDayLabel(day.period)
            )

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(UsageFormatters.cost(day.totalCost))
                    .font(.system(size: 27, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                Text("USD")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(UsageFormatters.compactTokens(day.totalTokens))
                        .font(.title3.weight(.semibold))
                    Text(language.text("総トークン", "Total tokens"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func weeklyChart(_ days: [DailyUsage], todayKey: String) -> some View {
        let activePeriod = selectedPeriod ?? todayKey

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                sectionTitle(language.text("過去7日間", "Last 7 days"))
                Button {
                    page = .calendar
                } label: {
                    Image(systemName: "calendar")
                }
                .buttonStyle(.borderless)
                .help(language.text("月間カレンダー", "Monthly calendar"))
                Spacer()
                Picker(
                    language.text("グラフ指標", "Chart metric"),
                    selection: $chartMetric
                ) {
                    ForEach(ChartMetric.allCases) { metric in
                        Text(metric.title(in: language)).tag(metric)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .tint(Color(nsColor: .labelColor))
                .frame(width: 126)
            }

            Chart(days) { day in
                BarMark(
                    x: .value(language.text("日", "Day"), day.period),
                    y: .value(
                        chartMetric.title(in: language),
                        chartMetric.value(for: day)
                    )
                )
                .foregroundStyle(Color(nsColor: .labelColor))
                .opacity(day.period == activePeriod ? 1 : 0.28)
                .cornerRadius(2)
                .accessibilityLabel(dayLabel(day.period))
                .accessibilityValue(
                    chartMetric.accessibilityValue(for: day, language: language)
                )
            }
            .chartXAxis {
                AxisMarks(values: days.map(\.period)) { value in
                    AxisValueLabel {
                        if let period = value.as(String.self) {
                            Text(dayLabel(period))
                                .fontWeight(period == activePeriod ? .semibold : .regular)
                                .foregroundStyle(
                                    period == activePeriod
                                        ? Color(nsColor: .labelColor)
                                        : Color(nsColor: .secondaryLabelColor)
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedPeriod = period
                                }
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let rawValue = value.as(Double.self) {
                            Text(chartMetric.axisLabel(rawValue))
                        }
                    }
                }
            }
            .chartXSelection(value: $chartSelection)
            .frame(height: 154)
            .animation(.easeInOut(duration: 0.18), value: chartMetric)
            .animation(.easeInOut(duration: 0.18), value: selectedPeriod)
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
    }

    private func errorView(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.secondary)
            Text(message)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(9)
        .background(.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text(language.text("使用量を取得中", "Loading usage"))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 460)
    }

    private var emptyView: some View {
        ContentUnavailableView(
            language.text("使用量データがありません", "No usage data"),
            systemImage: "chart.bar",
            description: Text(
                language.text(
                    "更新ボタンから ccusage のデータを取得できます。",
                    "Use Refresh to load data from ccusage."
                )
            )
        )
        .frame(minHeight: 460)
    }

    private var footer: some View {
        HStack {
            if let lastUpdated = viewModel.lastUpdated {
                Text(
                    language.text(
                        "\(DateFormatters.updatedAt.string(from: lastUpdated)) 更新",
                        "Updated \(DateFormatters.updatedAt.string(from: lastUpdated))"
                    )
                )
            } else {
                Text(language.text("未更新", "Not updated"))
            }
            Spacer()
            Text(language.text("ローカルデータ", "Local data"))
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 14)
        .frame(height: 32)
    }

    private func dayLabel(_ period: String) -> String {
        let timeZone = settings.aggregationTimeZone.timeZone
        guard let date = DateFormatters.date(fromPeriod: period, timeZone: timeZone) else {
            return period
        }
        return DateFormatters.weekdayString(
            from: date,
            language: language,
            timeZone: timeZone
        )
    }

    private func selectedDayLabel(_ period: String) -> String {
        let timeZone = settings.aggregationTimeZone.timeZone
        guard let date = DateFormatters.date(fromPeriod: period, timeZone: timeZone) else {
            return period
        }
        return DateFormatters.selectedDayString(
            from: date,
            language: language,
            timeZone: timeZone
        )
    }

    private func selectedUsage(in snapshot: UsageSnapshot) -> DailyUsage {
        guard let selectedPeriod,
              let selected = snapshot.days.first(where: { $0.period == selectedPeriod }) else {
            return snapshot.today
        }
        return selected
    }

    private func errorMessage(for error: Error) -> String {
        if let error = error as? CCUsageError {
            return error.message(in: language)
        }
        return language.text(
            "使用量を取得できませんでした: \(error.localizedDescription)",
            "Could not load usage: \(error.localizedDescription)"
        )
    }
}

private enum PopoverPage {
    case usage
    case calendar
    case settings
}

private enum ChartMetric: String, CaseIterable, Identifiable {
    case tokens
    case cost

    var id: String { rawValue }

    func title(in language: AppLanguage) -> String {
        switch self {
        case .tokens: language.text("トークン", "Tokens")
        case .cost: language.text("コスト", "Cost")
        }
    }

    func value(for day: DailyUsage) -> Double {
        self == .tokens ? Double(day.totalTokens) : day.totalCost
    }

    func axisLabel(_ value: Double) -> String {
        switch self {
        case .tokens:
            return UsageFormatters.compactTokens(Int64(value))
        case .cost:
            if value >= 1_000 { return "$\(Int(value / 1_000))K" }
            return "$\(Int(value))"
        }
    }

    func accessibilityValue(for day: DailyUsage, language: AppLanguage) -> String {
        switch self {
        case .tokens:
            return language.text(
                "\(UsageFormatters.compactTokens(day.totalTokens)) トークン",
                "\(UsageFormatters.compactTokens(day.totalTokens)) tokens"
            )
        case .cost:
            return UsageFormatters.cost(day.totalCost)
        }
    }
}
