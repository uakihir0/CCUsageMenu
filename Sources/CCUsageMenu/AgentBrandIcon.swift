import AppKit
import SwiftUI

struct AgentBrandIcon: View {
    let agent: String

    private var size: CGFloat {
        agent.lowercased() == "codex" ? 18 : 13
    }

    var body: some View {
        Group {
            if let image = AgentBrandImages.image(for: agent) {
                Image(nsImage: image)
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
            } else {
                Image(systemName: "command")
                    .resizable()
                    .scaledToFit()
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

private enum AgentBrandImages {
    private static let images: [String: NSImage] = [
        "claude": load(name: "claude", extension: "svg"),
        "codex": load(name: "codex", extension: "png")
    ].compactMapValues { $0 }

    static func image(for agent: String) -> NSImage? {
        images[agent.lowercased()]
    }

    private static func load(name: String, extension fileExtension: String) -> NSImage? {
        let fileName = "\(name).\(fileExtension)"
        let candidates = [
            Bundle.main.resourceURL?
                .appendingPathComponent("AgentIcons")
                .appendingPathComponent(fileName),
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent("Resources/AgentIcons")
                .appendingPathComponent(fileName)
        ].compactMap { $0 }

        return candidates.lazy
            .compactMap { NSImage(contentsOf: $0) }
            .first
    }
}
