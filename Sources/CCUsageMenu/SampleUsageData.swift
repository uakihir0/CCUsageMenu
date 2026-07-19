import Foundation

struct SampleUsageClient: UsageLoading {
    func load(
        from start: Date,
        through end: Date,
        timeZone: TimeZone
    ) async throws -> UsageReport {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return SampleUsageData.report(endingAt: end, calendar: calendar)
    }
}

enum SampleUsageData {
    private struct DayValues {
        let input: Int64
        let output: Int64
        let cacheCreation: Int64
        let cacheRead: Int64
        let cost: Double
    }

    private static let values = [
        DayValues(input: 420_000, output: 86_000, cacheCreation: 740_000, cacheRead: 4_800_000, cost: 18.42),
        DayValues(input: 610_000, output: 112_000, cacheCreation: 920_000, cacheRead: 7_400_000, cost: 26.81),
        DayValues(input: 380_000, output: 71_000, cacheCreation: 510_000, cacheRead: 3_900_000, cost: 14.26),
        DayValues(input: 890_000, output: 164_000, cacheCreation: 1_280_000, cacheRead: 9_600_000, cost: 39.74),
        DayValues(input: 720_000, output: 138_000, cacheCreation: 1_040_000, cacheRead: 8_200_000, cost: 32.18),
        DayValues(input: 540_000, output: 103_000, cacheCreation: 830_000, cacheRead: 6_300_000, cost: 23.95),
        DayValues(input: 810_000, output: 152_000, cacheCreation: 1_160_000, cacheRead: 10_900_000, cost: 37.62)
    ]

    static func snapshot(
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> UsageSnapshot {
        UsageSnapshot.make(
            report: report(endingAt: now, calendar: calendar),
            now: now,
            calendar: calendar
        )
    }

    static func report(
        endingAt end: Date,
        calendar: Calendar = .current
    ) -> UsageReport {
        let endOfRange = calendar.startOfDay(for: end)
        let days = values.enumerated().compactMap { index, value -> DailyUsage? in
            guard let date = calendar.date(
                byAdding: .day,
                value: index - (values.count - 1),
                to: endOfRange
            ) else {
                return nil
            }

            let codexCost = value.cost * 0.58
            let claudeCost = value.cost - codexCost
            let totalTokens = value.input + value.output + value.cacheCreation + value.cacheRead

            return DailyUsage(
                period: DateFormatters.periodString(
                    from: date,
                    timeZone: calendar.timeZone
                ),
                inputTokens: value.input,
                outputTokens: value.output,
                cacheCreationTokens: value.cacheCreation,
                cacheReadTokens: value.cacheRead,
                totalTokens: totalTokens,
                totalCost: value.cost,
                modelsUsed: ["openai.gpt-5.6-sol", "claude-opus-4-1"],
                modelBreakdowns: [
                    ModelBreakdown(
                        modelName: "openai.gpt-5.6-sol",
                        inputTokens: Int64(Double(value.input) * 0.62),
                        outputTokens: Int64(Double(value.output) * 0.58),
                        cacheCreationTokens: Int64(Double(value.cacheCreation) * 0.6),
                        cacheReadTokens: Int64(Double(value.cacheRead) * 0.65),
                        cost: codexCost
                    ),
                    ModelBreakdown(
                        modelName: "claude-opus-4-1",
                        inputTokens: Int64(Double(value.input) * 0.38),
                        outputTokens: Int64(Double(value.output) * 0.42),
                        cacheCreationTokens: Int64(Double(value.cacheCreation) * 0.4),
                        cacheReadTokens: Int64(Double(value.cacheRead) * 0.35),
                        cost: claudeCost
                    )
                ],
                metadata: UsageMetadata(agents: ["claude", "codex"])
            )
        }

        return UsageReport(
            daily: days,
            totals: UsageTotals(
                inputTokens: days.reduce(0) { $0 + $1.inputTokens },
                outputTokens: days.reduce(0) { $0 + $1.outputTokens },
                cacheCreationTokens: days.reduce(0) { $0 + $1.cacheCreationTokens },
                cacheReadTokens: days.reduce(0) { $0 + $1.cacheReadTokens },
                totalTokens: days.reduce(0) { $0 + $1.totalTokens },
                totalCost: days.reduce(0) { $0 + $1.totalCost }
            )
        )
    }
}
