import Foundation

protocol UsageLoading: Sendable {
    func load(from start: Date, through end: Date, timeZone: TimeZone) async throws -> UsageReport
}

struct CCUsageClient: UsageLoading {
    func load(from start: Date, through end: Date, timeZone: TimeZone) async throws -> UsageReport {
        try await Task.detached(priority: .userInitiated) {
            let executable = try CCUsageLocator.find()
            let process = Process()
            let standardOutput = Pipe()
            let standardError = Pipe()

            process.executableURL = executable
            process.arguments = [
                "daily",
                "--json",
                "--since", DateFormatters.periodString(from: start, timeZone: timeZone),
                "--until", DateFormatters.periodString(from: end, timeZone: timeZone),
                "--timezone", Self.commandIdentifier(for: timeZone),
                "--offline",
                "--no-color"
            ]
            process.standardOutput = standardOutput
            process.standardError = standardError
            process.environment = ProcessInfo.processInfo.environment.merging(
                ["NO_COLOR": "1"],
                uniquingKeysWith: { _, new in new }
            )

            do {
                try process.run()
            } catch {
                throw CCUsageError.launchFailed(error.localizedDescription)
            }

            let outputData = standardOutput.fileHandleForReading.readDataToEndOfFile()
            let errorData = standardError.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()

            guard process.terminationStatus == 0 else {
                let message = String(data: errorData, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                throw CCUsageError.commandFailed(message?.isEmpty == false ? message! : "終了コード \(process.terminationStatus)")
            }

            do {
                return try JSONDecoder().decode(UsageReport.self, from: outputData)
            } catch {
                throw CCUsageError.invalidOutput(error.localizedDescription)
            }
        }.value
    }

    static func commandIdentifier(for timeZone: TimeZone) -> String {
        timeZone.secondsFromGMT() == 0 ? "UTC" : timeZone.identifier
    }
}

enum CCUsageLocator {
    static func find(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
    ) throws -> URL {
        let fileManager = FileManager.default
        let pathCandidates = (environment["PATH"] ?? "")
            .split(separator: ":")
            .map { URL(fileURLWithPath: String($0)).appendingPathComponent("ccusage") }

        let commonCandidates = [
            homeDirectory.appendingPathComponent(".local/bin/ccusage"),
            homeDirectory.appendingPathComponent(".local/share/mise/shims/ccusage"),
            URL(fileURLWithPath: "/opt/homebrew/bin/ccusage"),
            URL(fileURLWithPath: "/usr/local/bin/ccusage")
        ]

        if let executable = (pathCandidates + commonCandidates).first(where: {
            fileManager.isExecutableFile(atPath: $0.path)
        }) {
            return executable
        }

        let miseNodeRoot = homeDirectory.appendingPathComponent(".local/share/mise/installs/node")
        if let versions = try? fileManager.contentsOfDirectory(
            at: miseNodeRoot,
            includingPropertiesForKeys: nil
        ) {
            let installedCandidates = versions
                .sorted { $0.lastPathComponent > $1.lastPathComponent }
                .map { $0.appendingPathComponent("bin/ccusage") }
            if let executable = installedCandidates.first(where: {
                fileManager.isExecutableFile(atPath: $0.path)
            }) {
                return executable
            }
        }

        throw CCUsageError.notInstalled
    }
}

enum CCUsageError: LocalizedError {
    case notInstalled
    case launchFailed(String)
    case commandFailed(String)
    case invalidOutput(String)

    var errorDescription: String? {
        message(in: .japanese)
    }

    func message(in language: AppLanguage) -> String {
        switch self {
        case .notInstalled:
            return language.text(
                "ccusage が見つかりません。PATH または ~/.local/bin にインストールしてください。",
                "ccusage was not found. Install it in PATH or ~/.local/bin."
            )
        case .launchFailed(let detail):
            return language.text(
                "ccusage を起動できませんでした: \(detail)",
                "Could not launch ccusage: \(detail)"
            )
        case .commandFailed(let detail):
            return language.text(
                "ccusage の取得に失敗しました: \(detail)",
                "ccusage failed to load usage: \(detail)"
            )
        case .invalidOutput(let detail):
            return language.text(
                "ccusage の出力を読み取れませんでした: \(detail)",
                "Could not read ccusage output: \(detail)"
            )
        }
    }
}
