#!/usr/bin/env swift

import AppKit
import CoreGraphics
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let output = root
    .appendingPathComponent("Sources/Viaduct/Resources/Assets.xcassets/AppIcon.appiconset")

try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

let canvasSize = 1024
let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!

guard let context = CGContext(
    data: nil,
    width: canvasSize,
    height: canvasSize,
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    fatalError("Unable to create icon context")
}

func color(_ hex: UInt32, alpha: CGFloat = 1) -> CGColor {
    CGColor(
        red: CGFloat((hex >> 16) & 0xff) / 255,
        green: CGFloat((hex >> 8) & 0xff) / 255,
        blue: CGFloat(hex & 0xff) / 255,
        alpha: alpha
    )
}

func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
    CGPoint(x: x, y: CGFloat(canvasSize) - y)
}

let rect = CGRect(x: 0, y: 0, width: canvasSize, height: canvasSize)
context.setAllowsAntialiasing(true)
context.setShouldAntialias(true)

let bgPath = CGPath(
    roundedRect: rect.insetBy(dx: 24, dy: 24),
    cornerWidth: 232,
    cornerHeight: 232,
    transform: nil
)
context.addPath(bgPath)
context.clip()

let baseGradient = CGGradient(
    colorsSpace: colorSpace,
    colors: [
        color(0x06104f).copy(alpha: 1)!,
        color(0x1520a6).copy(alpha: 1)!,
        color(0x6c2cff).copy(alpha: 1)!
    ] as CFArray,
    locations: [0, 0.58, 1]
)!
context.drawLinearGradient(baseGradient, start: point(150, 1040), end: point(930, 40), options: [])

let glowGradient = CGGradient(
    colorsSpace: colorSpace,
    colors: [
        color(0x1ea7ff, alpha: 0.56),
        color(0x1ea7ff, alpha: 0.0)
    ] as CFArray,
    locations: [0, 1]
)!
context.drawRadialGradient(
    glowGradient,
    startCenter: point(252, 258),
    startRadius: 16,
    endCenter: point(252, 258),
    endRadius: 540,
    options: []
)

let violetGlow = CGGradient(
    colorsSpace: colorSpace,
    colors: [
        color(0xb85cff, alpha: 0.62),
        color(0xb85cff, alpha: 0.0)
    ] as CFArray,
    locations: [0, 1]
)!
context.drawRadialGradient(
    violetGlow,
    startCenter: point(780, 780),
    startRadius: 28,
    endCenter: point(780, 780),
    endRadius: 520,
    options: []
)

context.resetClip()

context.setShadow(offset: CGSize(width: 0, height: 28), blur: 42, color: color(0x000000, alpha: 0.34))
context.addPath(bgPath)
context.setStrokeColor(color(0xffffff, alpha: 0.17))
context.setLineWidth(14)
context.strokePath()
context.setShadow(offset: .zero, blur: 0, color: nil)

let tunnelRect = CGRect(x: 246, y: 282, width: 532, height: 520)
let tunnelPath = CGMutablePath()
tunnelPath.move(to: point(246, 710))
tunnelPath.addLine(to: point(246, 510))
tunnelPath.addCurve(to: point(512, 282), control1: point(246, 374), control2: point(360, 282))
tunnelPath.addCurve(to: point(778, 510), control1: point(664, 282), control2: point(778, 374))
tunnelPath.addLine(to: point(778, 710))

context.setLineCap(.round)
context.setLineJoin(.round)
context.setShadow(offset: CGSize(width: 0, height: 18), blur: 34, color: color(0x18a8ff, alpha: 0.46))
context.addPath(tunnelPath)
context.setStrokeColor(color(0xeaf7ff, alpha: 0.97))
context.setLineWidth(78)
context.strokePath()
context.setShadow(offset: .zero, blur: 0, color: nil)

context.addPath(tunnelPath)
context.setStrokeColor(color(0x50c6ff, alpha: 0.38))
context.setLineWidth(24)
context.strokePath()

let innerPath = CGMutablePath()
innerPath.move(to: point(342, 704))
innerPath.addLine(to: point(342, 522))
innerPath.addCurve(to: point(512, 380), control1: point(342, 430), control2: point(418, 380))
innerPath.addCurve(to: point(682, 522), control1: point(606, 380), control2: point(682, 430))
innerPath.addLine(to: point(682, 704))

context.addPath(innerPath)
context.setStrokeColor(color(0x051068, alpha: 0.72))
context.setLineWidth(46)
context.strokePath()

func strokeLine(from start: CGPoint, to end: CGPoint, width: CGFloat, alpha: CGFloat) {
    context.setLineCap(.round)
    context.move(to: start)
    context.addLine(to: end)
    context.setStrokeColor(color(0xeaf7ff, alpha: alpha))
    context.setLineWidth(width)
    context.strokePath()
}

strokeLine(from: point(356, 794), to: point(476, 608), width: 42, alpha: 0.92)
strokeLine(from: point(668, 794), to: point(548, 608), width: 42, alpha: 0.92)
strokeLine(from: point(512, 608), to: point(512, 800), width: 30, alpha: 0.88)
strokeLine(from: point(328, 814), to: point(696, 814), width: 34, alpha: 0.9)

for (x, y, radius, fill) in [
    (336, 224, 34, 0x6ee7ff),
    (438, 172, 22, 0xffffff),
    (666, 230, 28, 0x8b5cff),
    (708, 336, 18, 0xffffff)
] {
    let dot = CGRect(
        x: CGFloat(x) - CGFloat(radius),
        y: CGFloat(canvasSize - y) - CGFloat(radius),
        width: CGFloat(radius * 2),
        height: CGFloat(radius * 2)
    )
    context.setFillColor(color(UInt32(fill), alpha: fill == 0xffffff ? 0.9 : 1))
    context.fillEllipse(in: dot)
}

guard let master = context.makeImage() else {
    fatalError("Unable to render master icon")
}

func writePNG(size points: Int, scale: Int, name: String) throws {
    let pixels = points * scale
    guard let resizedContext = CGContext(
        data: nil,
        width: pixels,
        height: pixels,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        fatalError("Unable to create \(name) context")
    }

    resizedContext.interpolationQuality = .high
    resizedContext.draw(master, in: CGRect(x: 0, y: 0, width: pixels, height: pixels))

    guard let resized = resizedContext.makeImage() else {
        fatalError("Unable to resize \(name)")
    }

    let bitmap = NSBitmapImageRep(cgImage: resized)
    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        fatalError("Unable to encode \(name)")
    }

    try data.write(to: output.appendingPathComponent(name))
}

let sizes = [
    (16, 1, "icon_16x16.png"),
    (16, 2, "icon_16x16@2x.png"),
    (32, 1, "icon_32x32.png"),
    (32, 2, "icon_32x32@2x.png"),
    (128, 1, "icon_128x128.png"),
    (128, 2, "icon_128x128@2x.png"),
    (256, 1, "icon_256x256.png"),
    (256, 2, "icon_256x256@2x.png"),
    (512, 1, "icon_512x512.png"),
    (512, 2, "icon_512x512@2x.png")
]

for icon in sizes {
    try writePNG(size: icon.0, scale: icon.1, name: icon.2)
}

print("Generated AppIcon.appiconset at \(output.path)")
