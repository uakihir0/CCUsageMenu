import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings

    private var language: AppLanguage { settings.language }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            settingRow(language.text("言語", "Language")) {
                Picker(language.text("言語", "Language"), selection: $settings.language) {
                    Text("日本語").tag(AppLanguage.japanese)
                    Text("English").tag(AppLanguage.english)
                }
            }

            Divider()

            settingRow(language.text("メニューバー表示", "Menu bar display")) {
                Picker(
                    language.text("メニューバー表示", "Menu bar display"),
                    selection: $settings.menuBarDisplay
                ) {
                    ForEach(MenuBarDisplay.allCases) { display in
                        Text(menuBarDisplayLabel(display)).tag(display)
                    }
                }
            }

            Divider()

            settingRow(language.text("更新頻度", "Refresh interval")) {
                Picker(
                    language.text("更新頻度", "Refresh interval"),
                    selection: $settings.refreshFrequency
                ) {
                    ForEach(RefreshFrequency.allCases) { frequency in
                        Text(refreshFrequencyLabel(frequency)).tag(frequency)
                    }
                }
            }

            Spacer()
        }
        .pickerStyle(.menu)
        .tint(Color(nsColor: .labelColor))
        .padding(.horizontal, 14)
        .padding(.top, 6)
    }

    private func settingRow<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.callout)
            Spacer()
            content()
                .labelsHidden()
                .frame(maxWidth: 142, alignment: .trailing)
        }
        .frame(height: 46)
    }

    private func menuBarDisplayLabel(_ display: MenuBarDisplay) -> String {
        switch display {
        case .none:
            language.text("表示なし", "Nothing")
        case .cost:
            language.text("今日の料金", "Today's cost")
        case .tokens:
            language.text("今日のトークン", "Today's tokens")
        }
    }

    private func refreshFrequencyLabel(_ frequency: RefreshFrequency) -> String {
        switch frequency {
        case .manual:
            language.text("手動のみ", "Manual")
        case .oneMinute:
            language.text("1分", "1 minute")
        case .fiveMinutes:
            language.text("5分", "5 minutes")
        case .fifteenMinutes:
            language.text("15分", "15 minutes")
        case .thirtyMinutes:
            language.text("30分", "30 minutes")
        case .hourly:
            language.text("60分", "60 minutes")
        }
    }
}
