import SwiftUI

/// The drawing of the unit circle.
struct TrigoView: View {
    @ObservedObject var model: TrigoModel
    var angleUnit: AngleUnit
    var standardAngles: Bool
    var sinCos: Bool
    var printing = false

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Canvas { context, size in
            TrigoDrawing(context: context,
                         size: size,
                         unit: Self.unit(for: size, printing: printing),
                         palette: Palette(dark: colorScheme == .dark && !printing),
                         view: self).draw()
        }
    }

    /// Length (in points) of the circle's radius.
    static func unit(for size: CGSize, printing: Bool = false) -> CGFloat {
        min(size.width, size.height) / (printing ? 4 : 3)
    }

    /// Converts a position in the view into coordinates in the circle's coordinate system.
    static func unitPoint(_ location: CGPoint, in size: CGSize) -> CGPoint {
        let unit = unit(for: size)
        return CGPoint(x: (location.x - size.width / 2) / unit, y: (size.height / 2 - location.y) / unit)
    }
}

/// The θ / cos(θ) / sin(θ) table of the side panel, at a fixed size.
struct TrigoValuesView: View {
    @ObservedObject var model: TrigoModel
    var angleUnit: AngleUnit

    @Environment(\.colorScheme) private var colorScheme

    private static let fontSize: CGFloat = 16
    /// Line spacing, in cap heights: 44 pt at this size (a little looser than in the printed box).
    private static let lineSpacing: CGFloat = 3.83

    var body: some View {
        Canvas { context, _ in
            let values = TrigoValues(context: context, fontSize: Self.fontSize, lineSpacing: Self.lineSpacing,
                                     color: Palette(dark: colorScheme == .dark).text)
            values.draw(theta: model.theta, unit: angleUnit, at: .zero)
        }
        .frame(height: TrigoValues.height(fontSize: Self.fontSize, lineSpacing: Self.lineSpacing))
    }
}

private struct Palette {
    var text, background, gray, circle, positive, negative, standard, box, boxBorder: Color

    init(dark: Bool) {
        text = dark ? .white : .black
        background = dark ? Color(white: 0.12) : .white
        gray = Color(white: 0.5)
        circle = dark ? Color(white: 0.67) : Color(white: 0.33)
        positive = dark ? Color(nsColor: .systemRed) : Color(red: 1, green: 0, blue: 0)
        negative = dark ? Color(nsColor: .systemBlue) : Color(red: 0, green: 0, blue: 1)
        standard = dark ? Color(white: 0.75) : Color(white: 0.25)
        box = dark ? Color(white: 0.22) : Color(white: 0.95)
        boxBorder = Color(white: 0.67)
    }
}

private struct TrigoDrawing {
    let context: GraphicsContext
    let size: CGSize
    let unit: CGFloat
    let palette: Palette
    let view: TrigoView

    private var theta: Double { view.model.theta }
    private var thetaColor: Color { theta >= 0 ? palette.positive : palette.negative }

    /// Point in the circle's coordinate system (origin at the center, y axis up) → point in the view.
    private func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: size.width / 2 + x, y: size.height / 2 - y)
    }

    // MARK: Text

    private func fontSize(_ size: CGFloat) -> CGFloat { max(9, size.rounded(.down)) }

    private func text(_ string: String, size: CGFloat, color: Color, kern: CGFloat = 0) -> Text {
        Text(verbatim: string)
            .font(.custom("Helvetica", fixedSize: fontSize(size)))
            .foregroundColor(color)
            .kerning(kern)
    }

    private let unbounded = CGSize(width: CGFloat.infinity, height: CGFloat.infinity)

    private func measure(_ text: Text) -> CGSize {
        context.resolve(text).measure(in: unbounded)
    }

    private func line(from a: CGPoint, to b: CGPoint, color: Color, style: StrokeStyle = StrokeStyle(lineWidth: 1)) {
        var path = Path()
        path.move(to: a)
        path.addLine(to: b)
        context.stroke(path, with: .color(color), style: style)
    }

    private func dot(at center: CGPoint, radius: CGFloat, color: Color) {
        let rect = CGRect(x: center.x - radius, y: center.y - radius, width: 2 * radius, height: 2 * radius)
        context.fill(Path(ellipseIn: rect), with: .color(color))
    }

    // MARK: Drawing

    func draw() {
        if !view.printing {
            // Draw the background
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(palette.background))
        }

        drawCircleAndAxes()

        let m = p(view.model.point.x * unit, view.model.point.y * unit)

        // Draw the coordinates
        let quarterTurns = theta * 2 / .pi
        if view.sinCos && !view.model.isDragging && abs(quarterTurns - quarterTurns.rounded(.towardZero)) > 0.01 {
            drawCoordinates()
        }

        // Draw point M on the circle and segment OM
        dot(at: m, radius: 0.03 * unit, color: thetaColor)
        line(from: p(0, 0), to: m, color: thetaColor)

        // Draw the arc of the angle
        var arc = Path()
        arc.move(to: p(0.25 * unit, 0))
        let steps = max(1, Int(abs(theta) / 0.02))
        for step in 1...steps {
            let t = theta * Double(step) / Double(steps)
            arc.addLine(to: p(0.25 * unit * cos(t), 0.25 * unit * sin(t)))
        }
        context.stroke(arc, with: .color(thetaColor))

        // Draw theta
        let label = TrigoModel.label(for: theta, unit: view.angleUnit)
        context.draw(text(label, size: 0.08 * unit, color: thetaColor),
                     at: p(0.4 * unit * cos(theta / 2), 0.4 * unit * sin(theta / 2)), anchor: .center)

        // On screen, the values are shown in the side panel
        if view.printing {
            drawResume()
        }
    }

    private func drawCircleAndAxes() {
        // Draw the axes
        line(from: p(-1.2 * unit, 0), to: p(1.2 * unit, 0), color: palette.gray)
        line(from: p(0, -1.2 * unit), to: p(0, 1.2 * unit), color: palette.gray)
        // Draw the arrowheads
        var arrows = Path()
        arrows.addLines([p(1.2 * unit, -0.02 * unit), p(1.26 * unit, 0), p(1.2 * unit, 0.02 * unit)])
        arrows.closeSubpath()
        arrows.addLines([p(-0.02 * unit, 1.2 * unit), p(0, 1.26 * unit), p(0.02 * unit, 1.2 * unit)])
        arrows.closeSubpath()
        context.fill(arrows, with: .color(palette.gray))

        // Draw the circle
        context.stroke(Path(ellipseIn: CGRect(origin: p(-unit, unit), size: CGSize(width: 2 * unit, height: 2 * unit))),
                       with: .color(palette.circle))

        // Draw the labels
        let labels: [(String, CGFloat, CGFloat)] = [
            ("0", -0.1, -0.15), ("1", 1.05, -0.15), (TrigoModel.decimal(-1, digits: 0), -1.15, -0.15), ("1", -0.1, 1.01), (TrigoModel.decimal(-1, digits: 0), -0.15, -1.15),
            ("x", 1.18, -0.15), ("y", 0.05, 1.15),
        ]
        for (string, x, y) in labels {
            context.draw(text(string, size: 0.08 * unit, color: palette.gray), at: p(x * unit, y * unit), anchor: .bottomLeading)
        }

        if view.standardAngles {
            for quarter in -2..<2 {
                for offset in [0, Double.pi / 6, Double.pi / 4, Double.pi / 3] {
                    // The half turn is written π (180°), not −π
                    let angle = offset + Double(quarter) * .pi / 2
                    drawRefPoint(angle == -.pi ? .pi : angle)
                }
            }
        }
    }

    private func drawRefPoint(_ angle: Double) {
        let x = unit * cos(angle)
        let y = unit * sin(angle)
        dot(at: p(x, y), radius: 0.012 * unit, color: palette.text)
        let label = TrigoModel.label(for: angle, unit: view.angleUnit)
        // The −π/2 label is moved down so that it does not overlap the axis's "−1"
        let distance = abs(angle + .pi / 2) < 0.001 ? 1.26 : 1.12
        // The 0 and π labels are raised just above the horizontal axis
        let lift = abs(sin(angle)) < 0.001 ? 0.06 * unit : 0
        context.draw(text(label, size: 0.07 * unit, color: palette.standard, kern: 1), at: p(distance * x, distance * y + lift), anchor: .center)
    }

    private func drawCoordinates() {
        let x = view.model.point.x * unit
        let y = view.model.point.y * unit
        let dash = StrokeStyle(lineWidth: 1, dash: [0.05 * unit, 0.05 * unit])
        line(from: p(0, y), to: p(x, y), color: palette.text, style: dash)
        line(from: p(x, 0), to: p(x, y), color: palette.text, style: dash)

        // Draw x
        context.draw(text(TrigoModel.decimal(cos(theta), digits: 3), size: 0.08 * unit, color: palette.text),
                     at: p(x, y >= 0 ? -0.12 * unit : 0), anchor: .bottom)
        // Draw y
        let yTag = text(TrigoModel.decimal(sin(theta), digits: 3), size: 0.08 * unit, color: palette.text)
        if x >= 0 {
            context.draw(yTag, at: p(-0.05 * unit, y), anchor: .trailing)
        } else {
            context.draw(yTag, at: p(0.05 * unit, y), anchor: .leading)
        }
    }

    /// Summary box: θ, cos(θ) and sin(θ).
    private func drawResume() {
        let size = fontSize(0.08 * unit)
        let values = TrigoValues(context: context, fontSize: size, color: palette.text)
        let height = TrigoValues.height(fontSize: size, lineSpacing: values.lineSpacing) + 0.04 * unit
        let maxWidth = measure(text("cos(T) = 0.12345", size: size, color: palette.text)).width

        let box = CGRect(origin: p(0.97 * unit, 0.98 * unit + height),
                         size: CGSize(width: maxWidth + 0.06 * unit, height: height))
        context.stroke(Path(box), with: .color(palette.boxBorder))
        context.fill(Path(box), with: .color(palette.box))

        values.draw(theta: theta, unit: view.angleUnit, at: p(unit, unit + height - 0.02 * unit))
    }
}

/// The three rows θ / cos(θ) / sin(θ), aligned on the "=" sign and set on their baseline.
/// Fractions are stacked (numerator, bar, denominator) and the radical sign is drawn as a path.
private struct TrigoValues {
    let context: GraphicsContext
    let fontSize: CGFloat
    /// Row height, in cap heights; 3.7 just fits a fraction whose numerator is a radical.
    var lineSpacing: CGFloat = 3.7
    let color: Color

    /// A numerator: text, or the square root of an integer.
    private enum Term {
        case text(String)
        case root(Int)
    }

    private let unbounded = CGSize(width: CGFloat.infinity, height: CGFloat.infinity)

    private static func font(_ size: CGFloat) -> NSFont {
        NSFont(name: "Helvetica", size: size) ?? .systemFont(ofSize: size)
    }

    static func height(fontSize: CGFloat, lineSpacing: CGFloat) -> CGFloat { 3 * lineSpacing * font(fontSize).capHeight }

    private var capHeight: CGFloat { Self.font(fontSize).capHeight }
    /// Stroke width (fraction bar, radical), close to Helvetica's thin strokes.
    private var stroke: CGFloat { 0.065 * fontSize }

    private func resolve(_ string: String, color: Color) -> GraphicsContext.ResolvedText {
        context.resolve(Text(verbatim: string).font(.custom("Helvetica", fixedSize: fontSize)).foregroundColor(color))
    }

    private func width(_ string: String) -> CGFloat {
        resolve(string, color: color).measure(in: unbounded).width
    }

    /// Writes `string` starting at `x` on the baseline `baseline` and returns its width.
    @discardableResult
    private func write(_ string: String, color: Color, x: CGFloat, baseline: CGFloat) -> CGFloat {
        let resolved = resolve(string, color: color)
        context.draw(resolved, at: CGPoint(x: x, y: baseline - resolved.firstBaseline(in: unbounded)), anchor: .topLeading)
        return resolved.measure(in: unbounded).width
    }

    /// `origin` is the top-left corner of the table.
    func draw(theta: Double, unit: AngleUnit, at origin: CGPoint) {
        let lineHeight = lineSpacing * capHeight
        let labels = ["θ = ", "cos(θ) = ", "sin(θ) = "]
        let x = origin.x + width(labels[1])

        for (index, label) in labels.enumerated() {
            // The baseline sits a little below the middle of the row: the radical needs room above
            let baseline = origin.y + (CGFloat(index) + 0.5) * lineHeight + 0.6 * capHeight
            write(label, color: color, x: x - width(label), baseline: baseline)
            switch index {
            case 0: writeAngle(TrigoModel.label(for: theta, unit: unit), x: x, baseline: baseline)
            case 1: writeValue(cos(theta), x: x, baseline: baseline)
            default: writeValue(sin(theta), x: x, baseline: baseline)
            }
        }
    }

    /// The angle: "5π/6" becomes a fraction, with the sign kept in front of the bar.
    private func writeAngle(_ label: String, x: CGFloat, baseline: CGFloat) {
        let negative = label.hasPrefix(TrigoModel.minus)
        let x = x + write(negative ? TrigoModel.minus : " ", color: color, x: x, baseline: baseline)
        let parts = (negative ? String(label.dropFirst()) : label).components(separatedBy: TrigoModel.div)
        if parts.count == 2 {
            writeFraction(.text(parts[0]), over: parts[1], color: color, x: x, baseline: baseline)
        } else {
            write(parts[0], color: color, x: x, baseline: baseline)
        }
    }

    /// Exact value for standard angles (1/2, √2/2, √3/2), approximate value otherwise.
    private func writeValue(_ value: Double, x: CGFloat, baseline: CGFloat) {
        let negative = value < -0.0001
        let x = x + write(negative ? TrigoModel.minus : " ", color: color, x: x, baseline: baseline)
        let magnitude = abs(value)
        if abs(magnitude - 0.866) < 0.0001 {
            writeFraction(.root(3), over: "2", color: color, x: x, baseline: baseline)
        } else if abs(magnitude - 0.7071) < 0.0001 {
            writeFraction(.root(2), over: "2", color: color, x: x, baseline: baseline)
        } else if abs(magnitude - 0.5) < 0.0001 {
            writeFraction(.text("1"), over: "2", color: color, x: x, baseline: baseline)
        } else {
            write((negative ? TrigoModel.thinSpace : "") + TrigoModel.decimal(magnitude, digits: 3), color: color, x: x, baseline: baseline)
        }
    }

    // MARK: Fractions and radicals

    /// Room taken by the radical sign to the left of the number, and overhang of the bar to the right.
    private var rootLead: CGFloat { 0.5 * fontSize }
    private var rootTrail: CGFloat { 0.08 * fontSize }

    private func width(of term: Term) -> CGFloat {
        switch term {
        case .text(let string): return width(string)
        case .root(let number): return rootLead + width("\(number)") + rootTrail
        }
    }

    /// Stacked fraction; the bar sits at half the cap height of the row.
    private func writeFraction(_ numerator: Term, over denominator: String, color: Color, x: CGFloat, baseline: CGFloat) {
        let x = x + 0.12 * fontSize // sets the bar off from the minus sign
        let pad = 0.12 * fontSize
        let gap = 0.24 * capHeight
        let numeratorWidth = width(of: numerator)
        let denominatorWidth = width(denominator)
        let barWidth = max(numeratorWidth, denominatorWidth) + 2 * pad
        let axis = baseline - 0.5 * capHeight

        var bar = Path()
        bar.move(to: CGPoint(x: x, y: axis))
        bar.addLine(to: CGPoint(x: x + barWidth, y: axis))
        context.stroke(bar, with: .color(color), lineWidth: stroke)

        let numeratorX = x + (barWidth - numeratorWidth) / 2
        let numeratorBaseline = axis - stroke / 2 - gap
        switch numerator {
        case .text(let string): write(string, color: color, x: numeratorX, baseline: numeratorBaseline)
        case .root(let number): writeRoot(of: number, color: color, x: numeratorX, baseline: numeratorBaseline)
        }
        write(denominator, color: color, x: x + (barWidth - denominatorWidth) / 2, baseline: axis + stroke / 2 + gap + capHeight)
    }

    /// "√n": hook, thick downstroke, upstroke and a bar covering the number.
    private func writeRoot(of number: Int, color: Color, x: CGFloat, baseline: CGFloat) {
        let numberWidth = write("\(number)", color: color, x: x + rootLead, baseline: baseline)
        let top = baseline - 1.22 * capHeight
        let hook = CGPoint(x: x + 0.14 * fontSize, y: baseline - 0.5 * capHeight)
        let bottom = CGPoint(x: x + 0.27 * fontSize, y: baseline)

        var thin = Path()
        thin.move(to: CGPoint(x: x + 0.04 * fontSize, y: baseline - 0.4 * capHeight))
        thin.addLine(to: hook)
        thin.move(to: bottom)
        thin.addLine(to: CGPoint(x: x + 0.44 * fontSize, y: top))
        thin.addLine(to: CGPoint(x: x + rootLead + numberWidth + rootTrail, y: top))
        context.stroke(thin, with: .color(color), style: StrokeStyle(lineWidth: stroke, lineCap: .round, lineJoin: .miter))

        var thick = Path()
        thick.move(to: hook)
        thick.addLine(to: bottom)
        context.stroke(thick, with: .color(color), style: StrokeStyle(lineWidth: 1.7 * stroke, lineCap: .round))
    }
}
