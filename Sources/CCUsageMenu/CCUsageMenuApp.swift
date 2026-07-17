import AppKit
import Combine
import SwiftUI

@main
@MainActor
enum CCUsageMenuApp {
    static func main() {
        let application = NSApplication.shared

        if let outputPath = screenshotOutputPath {
            application.setActivationPolicy(.prohibited)
            application.finishLaunching()

            do {
                try ScreenshotRenderer.render(to: outputPath)
            } catch {
                let message = "Screenshot generation failed: \(error)\n"
                FileHandle.standardError.write(Data(message.utf8))
                exit(EXIT_FAILURE)
            }
            return
        }

        let delegate = AppDelegate()

        application.delegate = delegate
        application.setActivationPolicy(.accessory)
        application.finishLaunching()

        withExtendedLifetime(delegate) {
            application.run()
        }
    }

    private static var screenshotOutputPath: String? {
        let arguments = CommandLine.arguments
        guard let flagIndex = arguments.firstIndex(of: "--generate-screenshot"),
              arguments.indices.contains(flagIndex + 1) else {
            return nil
        }
        return arguments[flagIndex + 1]
    }
}

@MainActor
private final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private let viewModel = UsageViewModel()
    private let settings = AppSettings()
    private let popover = NSPopover()
    private var statusItem: NSStatusItem?
    private var refreshTimer: Timer?
    private var outsideClickMonitor: Any?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        configurePopover()
        configureStatusItem()
        observeUsage()
        observeRefreshFrequency()

        Task {
            await viewModel.load()
        }
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self
        popover.contentSize = NSSize(width: 320, height: 620)
        popover.contentViewController = NSHostingController(
            rootView: UsagePopoverView(viewModel: viewModel, settings: settings)
        )
    }

    func applicationDidResignActive(_ notification: Notification) {
        closePopover()
    }

    func applicationWillTerminate(_ notification: Notification) {
        stopOutsideClickMonitoring()
    }

    func popoverDidClose(_ notification: Notification) {
        stopOutsideClickMonitoring()
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        guard let button = item.button else { return }

        button.image = CCUsageLogo.menuBarImage()
        button.imagePosition = .imageOnly
        button.imageScaling = .scaleProportionallyDown
        button.title = ""
        button.toolTip = "ccusage"
        button.setAccessibilityLabel("ccusage")
        button.target = self
        button.action = #selector(togglePopover)

        item.isVisible = true
        statusItem = item
    }

    private func observeUsage() {
        Publishers.CombineLatest3(
            viewModel.$snapshot,
            settings.$menuBarDisplay,
            settings.$language
        )
            .receive(on: RunLoop.main)
            .sink { [weak self] snapshot, display, language in
                self?.updateStatusItem(
                    snapshot: snapshot,
                    display: display,
                    language: language
                )
            }
            .store(in: &cancellables)
    }

    private func updateStatusItem(
        snapshot: UsageSnapshot?,
        display: MenuBarDisplay,
        language: AppLanguage
    ) {
        guard let item = statusItem, let button = item.button else { return }

        let title: String
        switch (display, snapshot) {
        case (.cost, .some(let snapshot)):
            title = UsageFormatters.menuCost(snapshot.today.totalCost)
        case (.tokens, .some(let snapshot)):
            title = UsageFormatters.compactTokens(snapshot.today.totalTokens)
        default:
            title = ""
        }

        button.title = title
        button.imagePosition = title.isEmpty ? .imageOnly : .imageLeading
        item.length = title.isEmpty ? NSStatusItem.squareLength : NSStatusItem.variableLength
        button.toolTip = language.text("ccusage - 今日の使用量", "ccusage - Today's usage")
    }

    private func observeRefreshFrequency() {
        settings.$refreshFrequency
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] frequency in
                self?.scheduleRefresh(every: frequency.seconds)
            }
            .store(in: &cancellables)
    }

    private func scheduleRefresh(every interval: TimeInterval?) {
        refreshTimer?.invalidate()
        refreshTimer = nil

        guard let interval else { return }
        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.viewModel.load(force: true)
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        refreshTimer = timer
    }

    @objc
    private func togglePopover() {
        if popover.isShown {
            closePopover()
            return
        }

        guard let button = statusItem?.button else { return }
        popover.show(
            relativeTo: button.bounds,
            of: button,
            preferredEdge: .minY
        )
        NSApplication.shared.activate(ignoringOtherApps: true)
        startOutsideClickMonitoring()
    }

    private func closePopover() {
        guard popover.isShown else {
            stopOutsideClickMonitoring()
            return
        }
        popover.performClose(nil)
    }

    private func startOutsideClickMonitoring() {
        guard outsideClickMonitor == nil else { return }

        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.closePopover()
            }
        }
    }

    private func stopOutsideClickMonitoring() {
        guard let outsideClickMonitor else { return }
        NSEvent.removeMonitor(outsideClickMonitor)
        self.outsideClickMonitor = nil
    }
}
