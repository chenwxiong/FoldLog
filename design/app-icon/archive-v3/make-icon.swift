import AppKit
import CoreGraphics
import CoreImage
import Foundation
import ImageIO
import UniformTypeIdentifiers

// Previous renderers: design/app-icon/archive-v1/ and archive-v2/.
// SVG geometry and native Icon Composer resources are built by make-icon.py.
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let folder = root.appendingPathComponent("design/app-icon/v3-connected-zero")
let main = folder.appendingPathComponent("connected-00")

func color(_ hex: String) -> CGColor {
    let value = UInt32(hex.replacingOccurrences(of: "#", with: ""), radix: 16)!
    return CGColor(srgbRed: Double((value >> 16) & 255) / 255,
                   green: Double((value >> 8) & 255) / 255,
                   blue: Double(value & 255) / 255, alpha: 1)
}
func context(_ width: Int, _ height: Int, alpha: Bool = false) -> CGContext {
    CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: alpha ? CGImageAlphaInfo.premultipliedLast.rawValue : CGImageAlphaInfo.noneSkipLast.rawValue)!
}
func load(_ url: URL) -> CGImage {
    let source = NSImage(contentsOf: url)!
    var rect = CGRect(x: 0, y: 0, width: 1024, height: 1024)
    return source.cgImage(forProposedRect: &rect, context: nil, hints: nil)!
}
func rasterize(_ url: URL, transparent: Bool = false) -> CGImage {
    let canvas = context(1024, 1024, alpha: transparent)
    canvas.interpolationQuality = .high
    canvas.draw(load(url), in: CGRect(x: 0, y: 0, width: 1024, height: 1024))
    return canvas.makeImage()!
}
func writePNG(_ image: CGImage, _ url: URL) {
    let output = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(output, image, nil)
    precondition(CGImageDestinationFinalize(output))
}

// Opaque, unmasked fallbacks. The active .icon supplies system effects.
let fallback = rasterize(main.appendingPathComponent("source.svg"))
let catalog = root.appendingPathComponent("FoldLog/Assets.xcassets/AppIcon.appiconset")
writePNG(fallback, catalog.appendingPathComponent("AppIcon.png"))
let ci = CIContext(options: [.workingColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!])
let dark = CIImage(cgImage: fallback).applyingFilter("CIColorControls", parameters: ["inputBrightness": -0.035])
let tint = CIImage(cgImage: fallback).applyingFilter("CIColorControls", parameters: ["inputSaturation": 0])
for (name, input) in [("AppIcon-dark.png", dark), ("AppIcon-tinted.png", tint)] {
    let rendered = ci.createCGImage(input, from: input.extent)!
    let canvas = context(1024, 1024)
    canvas.draw(rendered, in: CGRect(x: 0, y: 0, width: 1024, height: 1024))
    writePNG(canvas.makeImage()!, catalog.appendingPathComponent(name))
}
writePNG(rasterize(main.appendingPathComponent("mark.svg"), transparent: true),
         root.appendingPathComponent("FoldLog/Assets.xcassets/BrandMark.imageset/BrandMark.png"))

let width = 1800, height = 1550
let sheet = context(width, height)
sheet.translateBy(x: 0, y: CGFloat(height)); sheet.scaleBy(x: 1, y: -1)
let graphics = NSGraphicsContext(cgContext: sheet, flipped: true)
NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = graphics
sheet.setFillColor(color("#F2F1ED")); sheet.fill(CGRect(x: 0, y: 0, width: width, height: height))

func text(_ string: String, _ x: CGFloat, _ y: CGFloat, size: CGFloat,
          weight: NSFont.Weight = .regular, hex: String = "#202126", width: CGFloat = 900) {
    let paragraph = NSMutableParagraphStyle(); paragraph.lineSpacing = 5
    let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: NSColor(cgColor: color(hex))!, .paragraphStyle: paragraph]
    NSAttributedString(string: string, attributes: attrs).draw(in: CGRect(x: x, y: y, width: width, height: 150))
}
func image(_ source: CGImage, _ x: CGFloat, _ y: CGFloat, _ size: CGFloat, mask: Bool = false) {
    sheet.saveGState()
    let rect = CGRect(x: x, y: y, width: size, height: size)
    if mask {
        sheet.addPath(CGPath(roundedRect: rect, cornerWidth: size * 0.225, cornerHeight: size * 0.225, transform: nil))
        sheet.clip()
    }
    sheet.interpolationQuality = .high
    sheet.translateBy(x: rect.minX, y: rect.maxY); sheet.scaleBy(x: 1, y: -1)
    sheet.draw(source, in: CGRect(x: 0, y: 0, width: size, height: size))
    sheet.restoreGState()
}
func line(_ x: CGFloat, _ y: CGFloat, _ end: CGFloat) {
    sheet.setStrokeColor(color("#D8D6CE")); sheet.setLineWidth(1)
    sheet.move(to: CGPoint(x: x, y: y)); sheet.addLine(to: CGPoint(x: end, y: y)); sheet.strokePath()
}
let primary = load(main.appendingPathComponent("default.png"))
let alternative = load(folder.appendingPathComponent("plain-00/default.png"))
let before = load(root.appendingPathComponent("design/app-icon/v2-fold-light/fold-light/default.png"))
text("折记", 80, 58, size: 46, weight: .semibold)
text("FOLDLOG  /  ICON STUDY 03", 80, 125, size: 16, weight: .medium, hex: "#83745B")
text("珍珠白 · 香槟金 · 石墨黑", 1180, 76, size: 22, hex: "#746B5F", width: 540)
line(80, 183, 1720)

text("01 / 连页 00", 80, 227, size: 25, weight: .semibold)
text("连续书页 × 双位计数 · 已接入体验版", 80, 273, size: 18, hex: "#827664")
image(primary, 142, 345, 660)
text("连在一起的书，正在记录的数。", 80, 1062, size: 28, weight: .medium)
text("整片珍珠白书页连续相连，中间保持完整。\n定制 00 随页片微折，右侧数字以金色翻角点题。", 80, 1112, size: 21, hex: "#6F6E68", width: 810)

text("02 / 纯粹 00", 1000, 227, size: 25, weight: .semibold)
text("备选 · 保留纯石墨色数字", 1000, 273, size: 18, hex: "#827664")
image(alternative, 1150, 338, 380)
line(1000, 765, 1720)
text("上一版 → 本轮", 1000, 806, size: 18, hex: "#827664")
image(before, 1010, 863, 170)
text("→", 1220, 914, size: 28, hex: "#9C917E", width: 80)
image(primary, 1320, 863, 170)
text("连续的书页形状表达开合；00 补上计数与记录的含义。", 1000, 1070, size: 20, hex: "#6F6E68", width: 730)

line(80, 1232, 1720)
text("桌面小尺寸", 80, 1270, size: 18, weight: .medium)
for (i, size) in [CGFloat(60), 40, 29].enumerated() {
    let x = CGFloat(84 + i * 140)
    image(primary, x, 1330 + (60 - size) / 2, size)
    text("\(Int(size)) pt", x, 1420, size: 14, hex: "#827D72", width: 100)
}
text("系统外观 / Icon Composer 实际导出", 660, 1270, size: 18, weight: .medium, width: 1000)
for (i, file) in ["default", "dark", "tinted", "clear-light", "clear-dark"].enumerated() {
    let x = CGFloat(660 + i * 208)
    image(load(main.appendingPathComponent("\(file).png")), x, 1318, 100)
    text(["默认", "深色", "着色", "浅色透明", "深色透明"][i], x, 1440, size: 14, hex: "#827D72", width: 170)
}
text("原创 SVG 分层 · Native Icon Composer · iPhone Duo", 80, 1503, size: 14, hex: "#8E897E", width: 1500)
NSGraphicsContext.restoreGraphicsState()
writePNG(sheet.makeImage()!, folder.appendingPathComponent("icon-review.png"))
print("Updated fallbacks, BrandMark and design/app-icon/v3-connected-zero/icon-review.png")
