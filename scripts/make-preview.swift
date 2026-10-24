import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Compose real UI-test screenshots without changing their aspect ratios.
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let names = ["today-light", "today-dark", "history-with-records", "settings-with-goal"]
let images = names.map { name -> CGImage in
    let source = CGImageSourceCreateWithURL(root.appendingPathComponent("artifacts/\(name).png") as CFURL, nil)!
    return CGImageSourceCreateImageAtIndex(source, 0, nil)!
}
let columnWidth = 360, margin = 24
let columnHeight = Int((Double(columnWidth) * Double(images[0].height) / Double(images[0].width)).rounded())
let width = columnWidth * names.count + margin * (names.count + 1)
let height = columnHeight + margin * 2
let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
    bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
context.setFillColor(CGColor(gray: 0.90, alpha: 1))
context.fill(CGRect(x: 0, y: 0, width: width, height: height))
context.interpolationQuality = .high
for (index, image) in images.enumerated() {
    let rect = CGRect(x: margin + index * (columnWidth + margin), y: margin,
        width: columnWidth, height: columnHeight)
    context.saveGState()
    context.addPath(CGPath(roundedRect: rect, cornerWidth: 14, cornerHeight: 14, transform: nil))
    context.clip()
    context.draw(image, in: rect)
    context.restoreGState()
}
let output = root.appendingPathComponent("artifacts/preview.png")
let destination = CGImageDestinationCreateWithURL(output as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(destination, context.makeImage()!, nil)
precondition(CGImageDestinationFinalize(destination))
