// Génère l'icône de Trigonometry : swift make_icon.swift <dossier de sortie>
// puis : iconutil -c icns <dossier>/trigo.iconset -o trigo.icns
import AppKit

struct Style {
    var name: String
    var top, bottom: NSColor        // dégradé du fond
    var circle, axes, radius, cosine, sine, wedge, dot: NSColor
}

func rgb(_ hex: Int, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
}

let styles = [
    Style(name: "C-bleu", top: rgb(0x6FA0FF), bottom: rgb(0x2B55C8),
          circle: rgb(0xFFFFFF), axes: rgb(0xFFFFFF, 0.35), radius: rgb(0x7BE06A),
          cosine: rgb(0xFFFFFF), sine: rgb(0xFFFFFF), wedge: rgb(0x7BE06A, 0.45), dot: rgb(0x7BE06A)),
]

func line(_ a: NSPoint, _ b: NSPoint, _ color: NSColor, _ width: CGFloat, dash: [CGFloat] = []) {
    let path = NSBezierPath()
    path.move(to: a); path.line(to: b)
    path.lineWidth = width
    path.lineCapStyle = .round
    if !dash.isEmpty { path.setLineDash(dash, count: dash.count, phase: 0) }
    color.setStroke(); path.stroke()
}

func draw(_ s: Style, size: CGFloat) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size), bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let k = size / 1024
    let transform = NSAffineTransform(); transform.scale(by: k); transform.concat()

    // Forme macOS : carré arrondi de 824 pt dans un canevas de 1024 pt, avec ombre portée
    let shape = NSBezierPath(roundedRect: NSRect(x: 100, y: 100, width: 824, height: 824), xRadius: 185, yRadius: 185)
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.3)
    shadow.shadowBlurRadius = 22 * k
    shadow.shadowOffset = NSSize(width: 0, height: -10 * k)
    shadow.set()
    s.bottom.setFill(); shape.fill()
    NSGraphicsContext.restoreGraphicsState()

    NSGraphicsContext.saveGraphicsState()
    shape.addClip()
    NSGradient(starting: s.top, ending: s.bottom)!.draw(in: shape, angle: -90)

    let c = NSPoint(x: 512, y: 512)
    let r: CGFloat = 312
    let w: CGFloat = size <= 64 ? 1.5 : 1   // traits plus épais aux petites tailles
    let theta = 52.0 * Double.pi / 180
    let m = NSPoint(x: c.x + r * cos(theta), y: c.y + r * sin(theta))
    let foot = NSPoint(x: m.x, y: c.y)

    // Axes
    line(NSPoint(x: c.x - 385, y: c.y), NSPoint(x: c.x + 385, y: c.y), s.axes, 10 * w)
    line(NSPoint(x: c.x, y: c.y - 385), NSPoint(x: c.x, y: c.y + 385), s.axes, 10 * w)

    // Secteur de l'angle
    let wedge = NSBezierPath()
    wedge.move(to: c)
    wedge.appendArc(withCenter: c, radius: 140, startAngle: 0, endAngle: 52)
    wedge.close()
    s.wedge.setFill(); wedge.fill()

    // Cercle
    let circle = NSBezierPath(ovalIn: NSRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r))
    circle.lineWidth = 22 * w
    s.circle.setStroke(); circle.stroke()

    // cos, sin, rayon, point M
    line(c, foot, s.cosine, 32 * w)
    line(foot, m, s.sine, 32 * w)
    line(c, m, s.radius, 32 * w)
    let dotRadius: CGFloat = 40 * w
    let dot = NSBezierPath(ovalIn: NSRect(x: m.x - dotRadius, y: m.y - dotRadius, width: 2 * dotRadius, height: 2 * dotRadius))
    s.dot.setFill(); dot.fill()
    dot.lineWidth = 10
    s.top.setStroke(); dot.stroke()

    NSGraphicsContext.restoreGraphicsState()
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
// Aperçu en 1024 px
try! draw(styles[0], size: 1024).representation(using: .png, properties: [:])!
    .write(to: URL(fileURLWithPath: "\(out)/icon-1024.png"))

// Jeu d'icônes complet, à convertir avec iconutil
let iconset = "\(out)/trigo.iconset"
try? FileManager.default.createDirectory(atPath: iconset, withIntermediateDirectories: true)
for (points, scale) in [(16, 1), (16, 2), (32, 1), (32, 2), (128, 1), (128, 2), (256, 1), (256, 2), (512, 1), (512, 2)] {
    let name = scale == 1 ? "icon_\(points)x\(points).png" : "icon_\(points)x\(points)@2x.png"
    let data = draw(styles[0], size: CGFloat(points * scale)).representation(using: .png, properties: [:])!
    try! data.write(to: URL(fileURLWithPath: "\(iconset)/\(name)"))
}
