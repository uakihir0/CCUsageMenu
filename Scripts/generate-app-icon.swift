import AppKit

let outputPath = CommandLine.arguments.dropFirst().first ?? "Resources/AppIcon.png"
let size = 1024

guard let context = CGContext(
    data: nil,
    width: size,
    height: size,
    bitsPerComponent: 8,
    bytesPerRow: size * 4,
    space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    fatalError("Could not create icon context")
}

context.clear(CGRect(x: 0, y: 0, width: size, height: size))

let tileRect = CGRect(x: 72, y: 84, width: 880, height: 880)
let tile = CGPath(
    roundedRect: tileRect,
    cornerWidth: 210,
    cornerHeight: 210,
    transform: nil
)

context.saveGState()
context.setShadow(
    offset: CGSize(width: 0, height: -22),
    blur: 24,
    color: CGColor(gray: 0.08, alpha: 0.2)
)
context.addPath(tile)
context.setFillColor(CGColor(gray: 0.93, alpha: 1))
context.fillPath()
context.restoreGState()

let gradient = CGGradient(
    colorsSpace: CGColorSpaceCreateDeviceRGB(),
    colors: [
        CGColor(red: 233 / 255, green: 229 / 255, blue: 222 / 255, alpha: 1),
        CGColor(red: 250 / 255, green: 250 / 255, blue: 247 / 255, alpha: 1)
    ] as CFArray,
    locations: [0, 1]
)
context.saveGState()
context.addPath(tile)
context.clip()
if let gradient {
    context.drawLinearGradient(
        gradient,
        start: CGPoint(x: 512, y: tileRect.minY),
        end: CGPoint(x: 512, y: tileRect.maxY),
        options: []
    )
}
context.restoreGState()

context.addPath(tile)
context.setStrokeColor(CGColor(gray: 1, alpha: 0.9))
context.setLineWidth(4)
context.strokePath()

let logo = CGMutablePath()
logo.move(to: CGPoint(x: 1.75, y: 9))
logo.addLine(to: CGPoint(x: 1.75, y: 12))
logo.addCurve(
    to: CGPoint(x: 6, y: 14.25),
    control1: CGPoint(x: 1.75, y: 13.243),
    control2: CGPoint(x: 3.653, y: 14.25)
)
logo.addCurve(
    to: CGPoint(x: 10.25, y: 12),
    control1: CGPoint(x: 8.347, y: 14.25),
    control2: CGPoint(x: 10.25, y: 13.243)
)
logo.addLine(to: CGPoint(x: 10.25, y: 9))
logo.move(to: CGPoint(x: 1.75, y: 9))
logo.addCurve(
    to: CGPoint(x: 6, y: 11.25),
    control1: CGPoint(x: 1.75, y: 10.243),
    control2: CGPoint(x: 3.653, y: 11.25)
)
logo.addCurve(
    to: CGPoint(x: 10.25, y: 9),
    control1: CGPoint(x: 8.347, y: 11.25),
    control2: CGPoint(x: 10.25, y: 10.243)
)
logo.move(to: CGPoint(x: 1.75, y: 9))
logo.addCurve(
    to: CGPoint(x: 6, y: 6.75),
    control1: CGPoint(x: 1.75, y: 7.757),
    control2: CGPoint(x: 3.653, y: 6.75)
)
logo.addCurve(
    to: CGPoint(x: 10.25, y: 9),
    control1: CGPoint(x: 8.347, y: 6.75),
    control2: CGPoint(x: 10.25, y: 7.757)
)
logo.move(to: CGPoint(x: 5.75, y: 4))
logo.addCurve(
    to: CGPoint(x: 10, y: 1.75),
    control1: CGPoint(x: 5.75, y: 2.757),
    control2: CGPoint(x: 7.653, y: 1.75)
)
logo.addCurve(
    to: CGPoint(x: 14.25, y: 4),
    control1: CGPoint(x: 12.347, y: 1.75),
    control2: CGPoint(x: 14.25, y: 2.757)
)
logo.move(to: CGPoint(x: 14.25, y: 4))
logo.addCurve(
    to: CGPoint(x: 12, y: 5.986),
    control1: CGPoint(x: 14.25, y: 4.86),
    control2: CGPoint(x: 13.339, y: 5.607)
)
logo.move(to: CGPoint(x: 14.25, y: 4))
logo.addLine(to: CGPoint(x: 14.25, y: 7))
logo.addCurve(
    to: CGPoint(x: 12.75, y: 8.75),
    control1: CGPoint(x: 14.25, y: 7.623),
    control2: CGPoint(x: 13.522, y: 8.343)
)

func strokeLogo(color: NSColor, verticalOffset: CGFloat) {
    context.saveGState()
    context.translateBy(x: 176, y: 848 + verticalOffset)
    context.scaleBy(x: 42, y: -42)
    context.addPath(logo)
    context.setStrokeColor(color.cgColor)
    context.setLineWidth(1.5)
    context.setLineCap(.round)
    context.setLineJoin(.round)
    context.strokePath()
    context.restoreGState()
}

strokeLogo(
    color: NSColor(red: 122 / 255, green: 53 / 255, blue: 38 / 255, alpha: 0.14),
    verticalOffset: -6
)
strokeLogo(
    color: NSColor(red: 209 / 255, green: 111 / 255, blue: 82 / 255, alpha: 1),
    verticalOffset: 0
)

guard let renderedImage = context.makeImage() else {
    fatalError("Could not render icon image")
}
let bitmap = NSBitmapImageRep(cgImage: renderedImage)
guard let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Could not encode icon PNG")
}
try png.write(to: URL(fileURLWithPath: outputPath), options: .atomic)
