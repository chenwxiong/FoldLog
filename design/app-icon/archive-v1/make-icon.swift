import AppKit
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// Original vector artwork, shared by PNGs, SVG sources and the review sheet.
// No SF Symbols, hardware silhouettes, pre-masked corners or baked glass effects.
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let design = root.appendingPathComponent("design/app-icon")
let catalog = root.appendingPathComponent("FoldLog/Assets.xcassets/AppIcon.appiconset")
try FileManager.default.createDirectory(at: design, withIntermediateDirectories: true)
let previous = design.appendingPathComponent("previous-icon.png")
let oldIcon = catalog.appendingPathComponent("AppIcon.png")
if !FileManager.default.fileExists(atPath: previous.path), FileManager.default.fileExists(atPath: oldIcon.path) {
    try FileManager.default.copyItem(at: oldIcon, to: previous)
}

func color(_ hex: String) -> CGColor {
    let value = UInt32(hex.replacingOccurrences(of: "#", with: ""), radix: 16)!
    return CGColor(srgbRed: Double((value >> 16) & 255) / 255,
        green: Double((value >> 8) & 255) / 255, blue: Double(value & 255) / 255, alpha: 1)
}

enum Ink { case white, gold, fold, cutout }
struct Shape {
    let points: [CGPoint]
    let radius: CGFloat
    let ink: Ink
    init(_ coordinates: [(Double, Double)], _ ink: Ink, radius: CGFloat = 16) {
        points = coordinates.map { CGPoint(x: $0.0, y: $0.1) }
        self.radius = radius
        self.ink = ink
    }
}

struct Concept {
    let file: String
    let title: String
    let summary: String
    let shapes: [Shape]
}

let concepts = [
    Concept(file: "a-fold-tally", title: "A · 折页刻度", summary: "两片折面，一侧三道记录刻度。\n开合与计数，在一个标记里。", shapes: [
        Shape([(252,232),(484,344),(484,792),(252,680)], .white, radius: 22),
        Shape([(532,344),(794,216),(794,664),(532,792)], .gold, radius: 22),
        Shape([(304,406),(432,468),(432,496),(304,434)], .cutout, radius: 7),
        Shape([(304,494),(432,556),(432,584),(304,522)], .cutout, radius: 7),
        Shape([(304,582),(432,644),(432,672),(304,610)], .cutout, radius: 7)
    ]),
    Concept(file: "b-fold-loop", title: "B · 回折", summary: "连续翻折的几何纸带。\n更抽象，也更有动势。", shapes: [
        Shape([(228,310),(624,228),(796,398),(398,480)], .white, radius: 22),
        Shape([(398,480),(796,398),(624,744),(228,826)], .gold, radius: 22)
    ]),
    Concept(file: "c-fold-count", title: "C · 折记", summary: "三道记号与一笔金色折线。\n强调记录，保留折叠的转折。", shapes: [
        Shape([(270,324),(342,324),(342,742),(270,742)], .white, radius: 32),
        Shape([(408,284),(480,284),(480,702),(408,702)], .white, radius: 32),
        Shape([(546,244),(618,244),(618,662),(546,662)], .white, radius: 32),
        Shape([(254,720),(730,316),(802,404),(326,808)], .gold, radius: 16),
        Shape([(730,316),(802,404),(690,386)], .fold, radius: 10)
    ])
]

struct Palette {
    let name: String
    let background: String
    let white: String
    let gold: String
    let fold: String
    func hex(_ ink: Ink) -> String {
        switch ink {
        case .white: white
        case .gold: gold
        case .fold: fold
        case .cutout: background
        }
    }
}
let palettes = [
    Palette(name: "default", background: "#101114", white: "#F5F2EA", gold: "#D6B675", fold: "#A9813C"),
    Palette(name: "dark", background: "#08090B", white: "#DAD7D0", gold: "#BE9D61", fold: "#8B6835"),
    Palette(name: "tinted", background: "#151515", white: "#F4F4F4", gold: "#ABABAB", fold: "#6A6A6A")
]

// Rounded polygon commands are serialized directly into SVG, preserving geometry.
enum Command {
    case move(CGPoint), line(CGPoint), quad(CGPoint, CGPoint), close
}
func commands(_ shape: Shape) -> [Command] {
    var result: [Command] = []
    let points = shape.points
    for i in points.indices {
        let previous = points[(i + points.count - 1) % points.count]
        let vertex = points[i]
        let next = points[(i + 1) % points.count]
        func toward(_ other: CGPoint) -> CGPoint {
            let distance = hypot(other.x - vertex.x, other.y - vertex.y)
            let amount = min(shape.radius, distance * 0.35) / distance
            return CGPoint(x: vertex.x + (other.x - vertex.x) * amount,
                y: vertex.y + (other.y - vertex.y) * amount)
        }
        let entry = toward(previous), exit = toward(next)
        result.append(i == 0 ? .move(entry) : .line(entry))
        result.append(.quad(vertex, exit))
    }
    result.append(.close)
    return result
}
func path(_ shape: Shape) -> CGPath {
    let result = CGMutablePath()
    for command in commands(shape) {
        switch command {
        case .move(let p): result.move(to: p)
        case .line(let p): result.addLine(to: p)
        case .quad(let c, let p): result.addQuadCurve(to: p, control: c)
        case .close: result.closeSubpath()
        }
    }
    return result
}
func svgPath(_ shape: Shape) -> String {
    func point(_ p: CGPoint) -> String { String(format: "%.3f %.3f", Double(p.x), Double(p.y)) }
    return commands(shape).map { command in
        switch command {
        case .move(let p): "M \(point(p))"
        case .line(let p): "L \(point(p))"
        case .quad(let c, let p): "Q \(point(c)) \(point(p))"
        case .close: "Z"
        }
    }.joined(separator: " ")
}
func context(width: Int, height: Int, alpha: Bool) -> CGContext {
    CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: alpha ? CGImageAlphaInfo.premultipliedLast.rawValue : CGImageAlphaInfo.noneSkipLast.rawValue)!
}
func render(_ concept: Concept, _ palette: Palette, transparent: Bool = false) -> CGImage {
    let canvas = context(width: 1024, height: 1024, alpha: transparent)
    canvas.translateBy(x: 0, y: 1024); canvas.scaleBy(x: 1, y: -1)
    if !transparent {
        canvas.setFillColor(color(palette.background))
        canvas.fill(CGRect(x: 0, y: 0, width: 1024, height: 1024))
    }
    for shape in concept.shapes {
        canvas.saveGState()
        if transparent && shape.ink == .cutout { canvas.setBlendMode(.clear) }
        canvas.setFillColor(color(palette.hex(shape.ink)))
        canvas.addPath(path(shape)); canvas.fillPath()
        canvas.restoreGState()
    }
    return canvas.makeImage()!
}
func writePNG(_ image: CGImage, _ url: URL) {
    let output = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(output, image, nil)
    precondition(CGImageDestinationFinalize(output))
}
func writeSVG(_ concept: Concept, _ palette: Palette, to url: URL, layer: Ink? = nil) throws {
    var lines = ["<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"1024\" height=\"1024\" viewBox=\"0 0 1024 1024\">"]
    if layer == nil { lines.append("<rect width=\"1024\" height=\"1024\" fill=\"\(palette.background)\"/>") }
    if layer == .white {
        lines.append("<defs><mask id=\"cuts\"><rect width=\"1024\" height=\"1024\" fill=\"white\"/>")
        for shape in concept.shapes where shape.ink == .cutout {
            lines.append("<path d=\"\(svgPath(shape))\" fill=\"black\"/>")
        }
        lines.append("</mask></defs><g mask=\"url(#cuts)\">")
    }
    for shape in concept.shapes where layer == nil || shape.ink == layer {
        lines.append("<path d=\"\(svgPath(shape))\" fill=\"\(palette.hex(shape.ink))\"/>")
    }
    if layer == .white { lines.append("</g>") }
    lines.append("</svg>")
    try lines.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
}

for concept in concepts {
    let folder = design.appendingPathComponent(concept.file)
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    for palette in palettes {
        writePNG(render(concept, palette), folder.appendingPathComponent("\(palette.name).png"))
        try writeSVG(concept, palette, to: folder.appendingPathComponent("\(palette.name).svg"))
    }
}
let primary = concepts[0]
for ink in [Ink.white, .gold] {
    try writeSVG(primary, palettes[0], to: design.appendingPathComponent("a-fold-tally/layer-\(ink == .white ? "white" : "gold").svg"), layer: ink)
}
for (name, palette) in zip(["AppIcon.png", "AppIcon-dark.png", "AppIcon-tinted.png"], palettes) {
    writePNG(render(primary, palette), catalog.appendingPathComponent(name))
}
let entries: [[String: Any]] = palettes.enumerated().map { index, palette in
    var entry: [String: Any] = ["filename": index == 0 ? "AppIcon.png" : "AppIcon-\(palette.name).png",
        "idiom": "universal", "platform": "ios", "size": "1024x1024"]
    if index > 0 { entry["appearances"] = [["appearance": "luminosity", "value": palette.name]] }
    return entry
}
let contents: [String: Any] = ["images": entries, "info": ["author": "xcode", "version": 1]]
try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
    .write(to: catalog.appendingPathComponent("Contents.json"))
let markFolder = root.appendingPathComponent("FoldLog/Assets.xcassets/BrandMark.imageset")
try FileManager.default.createDirectory(at: markFolder, withIntermediateDirectories: true)
writePNG(render(primary, palettes[0], transparent: true), markFolder.appendingPathComponent("BrandMark.png"))
try """
{"images":[{"filename":"BrandMark.png","idiom":"universal"}],"info":{"author":"xcode","version":1}}
""".write(to: markFolder.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)

// Review sheet only: corner masks preview how the OS crops square deliverables.
let sheet = context(width: 1800, height: 1290, alpha: false)
let graphics = NSGraphicsContext(cgContext: sheet, flipped: true)
sheet.translateBy(x: 0, y: 1290); sheet.scaleBy(x: 1, y: -1)
NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = graphics
sheet.setFillColor(color("#F1F0EC")); sheet.fill(CGRect(x: 0, y: 0, width: 1800, height: 1290))
func text(_ string: String, at x: CGFloat, _ y: CGFloat, size: CGFloat, weight: NSFont.Weight = .regular, hex: String = "#161719", width: CGFloat = 530) {
    let paragraph = NSMutableParagraphStyle(); paragraph.lineSpacing = 5
    let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: NSColor(cgColor: color(hex))!, .paragraphStyle: paragraph]
    NSAttributedString(string: string, attributes: attrs).draw(in: CGRect(x: x, y: y, width: width, height: 140))
}
func icon(_ image: CGImage, x: CGFloat, y: CGFloat, size: CGFloat) {
    let rect = CGRect(x: x, y: y, width: size, height: size)
    sheet.saveGState()
    sheet.addPath(CGPath(roundedRect: rect, cornerWidth: size * 0.225, cornerHeight: size * 0.225, transform: nil))
    sheet.clip(); sheet.interpolationQuality = .high
    sheet.translateBy(x: rect.minX, y: rect.maxY); sheet.scaleBy(x: 1, y: -1)
    sheet.draw(image, in: CGRect(x: 0, y: 0, width: size, height: size))
    sheet.restoreGState()
}
text("折记 / FoldLog", at: 64, 50, size: 38, weight: .semibold, width: 1100)
text("iPhone Duo 专属 · App Icon 首轮设计", at: 64, 110, size: 21, hex: "#6A6862", width: 1100)
text("BLACK / WHITE / GOLD", at: 1330, 64, size: 16, weight: .medium, hex: "#886424", width: 420)
for (index, concept) in concepts.enumerated() {
    let x = CGFloat(64 + index * 576)
    text(index == 0 ? "01  /  推荐 · 已接入体验版" : String(format: "%02d  /  备选方向", index + 1),
        at: x, 202, size: 16, weight: .medium, hex: index == 0 ? "#886424" : "#79766E")
    icon(render(concept, palettes[0]), x: x + 76, y: 254, size: 360)
    text(concept.title, at: x, 656, size: 28, weight: .semibold)
    text(concept.summary, at: x, 706, size: 19, hex: "#6A6862")
    text("小尺寸辨识", at: x, 822, size: 15, hex: "#79766E")
    for (offset, size) in [CGFloat(60), 40, 29].enumerated() {
        let offsetX = x + CGFloat(offset * 128)
        icon(render(concept, palettes[0]), x: offsetX, y: 868 + (60 - size) / 2, size: size)
        text("\(Int(size)) pt", at: offsetX, 945, size: 13, hex: "#79766E", width: 100)
    }
    for (appearance, palette) in palettes.enumerated() {
        let offsetX = x + CGFloat(appearance * 148)
        icon(render(concept, palette), x: offsetX, y: 1030, size: 100)
        text(["默认", "深色", "着色基底"][appearance], at: offsetX, 1150, size: 15, hex: "#6A6862", width: 130)
    }
}
text("原创矢量图形 · 1024 × 1024 · 正式素材保持方形，由系统裁切圆角", at: 64, 1236, size: 15, hex: "#79766E", width: 1600)
NSGraphicsContext.restoreGraphicsState()
writePNG(sheet.makeImage()!, design.appendingPathComponent("icon-directions.png"))
print("Generated 3 concepts, 3 appearances, SVG layers, app assets and design/app-icon/icon-directions.png")
