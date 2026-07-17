import SwiftUI

struct DailyUsageDetails: View {
    let day: DailyUsage
    let language: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            serviceDetails
            tokenDetails
            modelDetails
        }
    }

    private var serviceDetails: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionTitle(language.text("サービス", "Services"))

            HStack(spacing: 10) {
                let agents = day.metadata?.agents ?? []
                if agents.isEmpty {
                    Text(language.text("利用なし", "No usage"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(agents, id: \.self) { agent in
                        HStack(spacing: 4) {
                            AgentBrandIcon(agent: agent)
                            Text(agent.capitalized)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(height: 18, alignment: .leading)
        }
    }

    private var tokenDetails: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle(language.text("トークン内訳", "Token breakdown"))
            detailRow(language.text("入力", "Input"), value: day.inputTokens)
            detailRow(language.text("出力", "Output"), value: day.outputTokens)
            detailRow(
                language.text("キャッシュ作成", "Cache creation"),
                value: day.cacheCreationTokens
            )
            detailRow(
                language.text("キャッシュ読込", "Cache read"),
                value: day.cacheReadTokens
            )
        }
    }

    @ViewBuilder
    private var modelDetails: some View {
        if !day.modelBreakdowns.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                sectionTitle(language.text("モデル別", "By model"))
                ForEach(day.modelBreakdowns.sorted(by: { $0.cost > $1.cost })) { model in
                    HStack(spacing: 8) {
                        Image(systemName: "cpu")
                            .foregroundStyle(.secondary)
                            .frame(width: 16)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(model.modelName)
                                .font(.callout)
                                .lineLimit(1)
                            Text(
                                language.text(
                                    "\(UsageFormatters.compactTokens(model.totalTokens)) トークン",
                                    "\(UsageFormatters.compactTokens(model.totalTokens)) tokens"
                                )
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(UsageFormatters.cost(model.cost))
                            .font(.callout.monospacedDigit())
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private func detailRow(_ title: String, value: Int64) -> some View {
        HStack {
            Circle()
                .fill(.secondary)
                .frame(width: 6, height: 6)
            Text(title)
            Spacer()
            Text(UsageFormatters.compactTokens(value))
                .font(.callout.monospacedDigit())
        }
        .padding(.vertical, 1)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
    }
}
