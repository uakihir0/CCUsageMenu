import AppKit
import SwiftUI

enum CCUsageLogo {
    static let path: CGPath = {
        let path = CGMutablePath()

        path.move(to: CGPoint(x: 1.75, y: 9))
        path.addLine(to: CGPoint(x: 1.75, y: 12))
        path.addCurve(
            to: CGPoint(x: 6, y: 14.25),
            control1: CGPoint(x: 1.75, y: 13.243),
            control2: CGPoint(x: 3.653, y: 14.25)
        )
        path.addCurve(
            to: CGPoint(x: 10.25, y: 12),
            control1: CGPoint(x: 8.347, y: 14.25),
            control2: CGPoint(x: 10.25, y: 13.243)
        )
        path.addLine(to: CGPoint(x: 10.25, y: 9))

        path.move(to: CGPoint(x: 1.75, y: 9))
        path.addCurve(
            to: CGPoint(x: 6, y: 11.25),
            control1: CGPoint(x: 1.75, y: 10.243),
            control2: CGPoint(x: 3.653, y: 11.25)
        )
        path.addCurve(
            to: CGPoint(x: 10.25, y: 9),
            control1: CGPoint(x: 8.347, y: 11.25),
            control2: CGPoint(x: 10.25, y: 10.243)
        )

        path.move(to: CGPoint(x: 1.75, y: 9))
        path.addCurve(
            to: CGPoint(x: 6, y: 6.75),
            control1: CGPoint(x: 1.75, y: 7.757),
            control2: CGPoint(x: 3.653, y: 6.75)
        )
        path.addCurve(
            to: CGPoint(x: 10.25, y: 9),
            control1: CGPoint(x: 8.347, y: 6.75),
            control2: CGPoint(x: 10.25, y: 7.757)
        )

        path.move(to: CGPoint(x: 5.75, y: 4))
        path.addCurve(
            to: CGPoint(x: 10, y: 1.75),
            control1: CGPoint(x: 5.75, y: 2.757),
            control2: CGPoint(x: 7.653, y: 1.75)
        )
        path.addCurve(
            to: CGPoint(x: 14.25, y: 4),
            control1: CGPoint(x: 12.347, y: 1.75),
            control2: CGPoint(x: 14.25, y: 2.757)
        )

        path.move(to: CGPoint(x: 14.25, y: 4))
        path.addCurve(
            to: CGPoint(x: 12, y: 5.986),
            control1: CGPoint(x: 14.25, y: 4.86),
            control2: CGPoint(x: 13.339, y: 5.607)
        )

        path.move(to: CGPoint(x: 14.25, y: 4))
        path.addLine(to: CGPoint(x: 14.25, y: 7))
        path.addCurve(
            to: CGPoint(x: 12.75, y: 8.75),
            control1: CGPoint(x: 14.25, y: 7.623),
            control2: CGPoint(x: 13.522, y: 8.343)
        )

        return path
    }()

    static func menuBarImage() -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { _ in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }

            context.saveGState()
            context.translateBy(x: 0.6, y: 17.4)
            context.scaleBy(x: 1.05, y: -1.05)
            context.addPath(path)
            context.setStrokeColor(NSColor.black.cgColor)
            context.setLineWidth(1.5)
            context.setLineCap(.round)
            context.setLineJoin(.round)
            context.strokePath()
            context.restoreGState()
            return true
        }
        image.isTemplate = true
        return image
    }
}

struct CCUsageLogoShape: Shape {
    func path(in rect: CGRect) -> Path {
        var transform = CGAffineTransform(
            scaleX: rect.width / 16,
            y: rect.height / 16
        )
        guard let scaledPath = CCUsageLogo.path.copy(using: &transform) else {
            return Path()
        }
        return Path(scaledPath)
    }
}

struct CCUsageLogoView: View {
    var size: CGFloat = 24

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size / 4)
                .fill(.primary.opacity(0.08))
            CCUsageLogoShape()
                .stroke(
                    .primary.opacity(0.85),
                    style: StrokeStyle(
                        lineWidth: size * 1.5 / 16,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
                .padding(size * 56 / 512)
        }
        .frame(width: size, height: size)
        .accessibilityLabel("ccusage")
    }
}
