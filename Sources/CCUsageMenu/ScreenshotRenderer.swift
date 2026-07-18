import AppKit
import SwiftUI

@MainActor
enum ScreenshotRenderer {
    static func render(
        to outputPath: String,
        language: AppLanguage
    ) throws {
        let now = Date()
        let suiteName = "local.ccusage.menu.screenshot"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            throw ScreenshotError.couldNotCreateSettings
        }

        defaults.removePersistentDomain(forName: suiteName)
        defaults.set(language.rawValue, forKey: "settings.language")
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let viewModel = UsageViewModel(
            client: SampleUsageClient(),
            snapshot: SampleUsageData.snapshot(now: now),
            lastUpdated: now
        )
        let settings = AppSettings(defaults: defaults)
        let content = UsagePopoverView(
            viewModel: viewModel,
            settings: settings,
            screenshotMode: true
        )
            .background(Color(nsColor: .windowBackgroundColor))
            .environment(\.colorScheme, .light)

        let size = NSSize(width: 320, height: 620)
        let hostingView = NSHostingView(rootView: content)
        hostingView.frame = NSRect(origin: .zero, size: size)

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.backgroundColor = .windowBackgroundColor
        window.contentView = hostingView
        window.setFrameOrigin(NSPoint(x: -10_000, y: -10_000))
        window.orderFront(nil)

        hostingView.layoutSubtreeIfNeeded()
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.4))
        hostingView.layoutSubtreeIfNeeded()

        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size.width * 2),
            pixelsHigh: Int(size.height * 2),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            throw ScreenshotError.couldNotRender
        }

        bitmap.size = size
        hostingView.cacheDisplay(in: hostingView.bounds, to: bitmap)
        window.orderOut(nil)

        guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
            throw ScreenshotError.couldNotRender
        }

        let outputURL = URL(fileURLWithPath: outputPath)
        try FileManager.default.createDirectory(
            at: outputURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try pngData.write(to: outputURL, options: .atomic)
    }
}

private enum ScreenshotError: Error {
    case couldNotCreateSettings
    case couldNotRender
}
