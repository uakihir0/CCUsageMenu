import SwiftUI

struct MonthlyCalendarView: View {
    @ObservedObject var viewModel: MonthlyUsageViewModel
    @ObservedObject var settings: AppSettings
    @State private var metric: MonthMetric = .cost
    @State private var selectedPeriod: String?

    private var language: AppLanguage { settings.language }
    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 2),
        count: 7
    )

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                monthNavigation
                summary
                weekdayHeader
                calendarGrid

                if let error = viewModel.loadError {
                    errorView(errorMessage(for: error))
                }

                if let selectedDay {
                    Divider()
                        .padding(.vertical, 4)
                    DailyUsageDetails(day: selectedDay, language: language)
                }
            }
            .padding(12)
        }
        .scrollIndicators(.hidden)
        .task {
            await viewModel.load()
        }
        .onChange(of: viewModel.selectedMonth) { _, _ in
            selectedPeriod = nil
        }
    }

    private var monthNavigation: some View {
        HStack {
            Button {
                Task { await viewModel.moveMonth(by: -1) }
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.borderless)
            .help(language.text("前の月", "Previous month"))

            Spacer()

            Text(monthLabel)
                .font(.headline)

            Spacer()

            if viewModel.isLoading {
                ProgressView()
                    .controlSize(.small)
                    .frame(width: 16, height: 16)
            } else {
                Button {
                    Task { await viewModel.moveMonth(by: 1) }
                } label: {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.borderless)
                .disabled(!viewModel.canMoveForward)
                .help(language.text("次の月", "Next month"))
            }
        }
        .frame(height: 28)
    }

    private var summary: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(summaryTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(summaryPrimaryValue)
                    .font(.title3.weight(.semibold).monospacedDigit())
            }

            Spacer()

            Picker(
                language.text("表示指標", "Display metric"),
                selection: $metric
            ) {
                ForEach(MonthMetric.allCases) { metric in
                    Text(metric.title(in: language)).tag(metric)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .tint(Color(nsColor: .labelColor))
            .frame(width: 126)
        }
        .frame(height: 42)
    }

    private var weekdayHeader: some View {
        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var calendarGrid: some View {
        let dates = MonthCalendar.dates(in: viewModel.selectedMonth)

        return LazyVGrid(columns: columns, spacing: 2) {
            ForEach(Array(dates.enumerated()), id: \.offset) { _, date in
                if let date {
                    dayCell(date)
                } else {
                    Color.clear
                        .frame(height: 43)
                }
            }
        }
    }

    private func dayCell(_ date: Date) -> some View {
        let key = DateFormatters.period.string(from: date)
        let usage = usage(for: key)
        let isSelected = selectedPeriod == key

        return Button {
            selectedPeriod = isSelected ? nil : key
        } label: {
            VStack(spacing: 2) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.caption.weight(isSelected ? .semibold : .regular))
                Text(usage.map(metric.cellValue) ?? "")
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 39)
            .padding(.vertical, 2)
            .background(
                isSelected ? Color.primary.opacity(0.1) : Color.clear,
                in: RoundedRectangle(cornerRadius: 3)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(selectedDayLabel(date))
        .accessibilityValue(usage.map(metric.accessibilityValue) ?? "")
    }

    private var summaryTitle: String {
        guard let selectedPeriod,
              let date = DateFormatters.period.date(from: selectedPeriod) else {
            return language.text("月合計", "Month total")
        }
        return selectedDayLabel(date)
    }

    private var summaryPrimaryValue: String {
        guard let selectedDay else {
            return metric == .cost
                ? UsageFormatters.cost(viewModel.totalCost)
                : UsageFormatters.compactTokens(viewModel.totalTokens)
        }
        return metric == .cost
            ? UsageFormatters.cost(selectedDay.totalCost)
            : UsageFormatters.compactTokens(selectedDay.totalTokens)
    }

    private var selectedDay: DailyUsage? {
        guard let selectedPeriod else { return nil }
        return usage(for: selectedPeriod) ?? .empty(period: selectedPeriod)
    }

    private var monthLabel: String {
        let formatter = DateFormatter()
        formatter.locale = language.locale
        formatter.dateFormat = language == .japanese ? "yyyy年M月" : "MMMM yyyy"
        return formatter.string(from: viewModel.selectedMonth)
    }

    private var weekdaySymbols: [String] {
        let formatter = DateFormatter()
        formatter.locale = language.locale
        let symbols = formatter.veryShortWeekdaySymbols ?? []
        let first = max(0, Calendar.current.firstWeekday - 1)
        return Array(symbols[first...] + symbols[..<first])
    }

    private func usage(for period: String) -> DailyUsage? {
        viewModel.days.first(where: { $0.period == period })
    }

    private func selectedDayLabel(_ date: Date) -> String {
        language == .japanese
            ? DateFormatters.selectedDay.string(from: date)
            : DateFormatters.selectedDayEnglish.string(from: date)
    }

    private func errorView(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.secondary)
            Text(message)
                .font(.caption)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(8)
        .background(.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
    }

    private func errorMessage(for error: Error) -> String {
        if let error = error as? CCUsageError {
            return error.message(in: language)
        }
        return language.text(
            "月間データを取得できませんでした。",
            "Could not load monthly usage."
        )
    }
}

private enum MonthMetric: String, CaseIterable, Identifiable {
    case cost
    case tokens

    var id: String { rawValue }

    func title(in language: AppLanguage) -> String {
        switch self {
        case .cost: language.text("コスト", "Cost")
        case .tokens: language.text("トークン", "Tokens")
        }
    }

    func cellValue(_ usage: DailyUsage) -> String {
        switch self {
        case .cost:
            return "$\(Int(floor(usage.totalCost)))"
        case .tokens:
            return UsageFormatters.compactTokens(usage.totalTokens)
        }
    }

    func accessibilityValue(_ usage: DailyUsage) -> String {
        switch self {
        case .cost:
            return UsageFormatters.cost(usage.totalCost)
        case .tokens:
            return UsageFormatters.compactTokens(usage.totalTokens)
        }
    }
}
