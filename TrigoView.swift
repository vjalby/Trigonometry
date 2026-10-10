import SwiftUI

/// Le dessin du cercle trigonométrique.
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

    /// Longueur (en points) du rayon du cercle.
    static func unit(for size: CGSize, printing: Bool = false) -> CGFloat {
        min(size.width, size.height) / (printing ? 4 : 3)
    }

    /// Convertit une position dans la vue en coordonnées dans le repère du cercle.
    static func unitPoint(_ location: CGPoint, in size: CGSize) -> CGPoint {
        let unit = unit(for: size)
        return CGPoint(x: (location.x - size.width / 2) / unit, y: (size.height / 2 - location.y) / unit)
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
        standard = dark ? Color(nsColor: .systemPink) : Color(red: 1, green: 0, blue: 1)
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

    /// Point du repère (origine au centre, axe y vers le haut) → point de la vue.
    private func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: size.width / 2 + x, y: size.height / 2 - y)
    }

    // MARK: Texte

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

    // MARK: Dessin

    func draw() {
        if !view.printing {
            // Trace le fond et le bord
            let bounds = CGRect(origin: .zero, size: size)
            context.fill(Path(bounds), with: .color(palette.background))
            context.stroke(Path(bounds), with: .color(palette.text))
        }

        drawCircleAndAxes()

        let m = p(view.model.point.x * unit, view.model.point.y * unit)

        // Affichage des coordonnées
        let quarterTurns = theta * 2 / .pi
        if view.sinCos && !view.model.isDragging && abs(quarterTurns - quarterTurns.rounded(.towardZero)) > 0.01 {
            drawCoordinates()
        }

        // Affichage du point M sur le cercle et du segment OM
        dot(at: m, radius: 0.03 * unit, color: thetaColor)
        line(from: p(0, 0), to: m, color: thetaColor)

        // Affichage de l'arc de l'angle
        var arc = Path()
        arc.move(to: p(0.25 * unit, 0))
        let steps = max(1, Int(abs(theta) / 0.02))
        for step in 1...steps {
            let t = theta * Double(step) / Double(steps)
            arc.addLine(to: p(0.25 * unit * cos(t), 0.25 * unit * sin(t)))
        }
        context.stroke(arc, with: .color(thetaColor))

        // Affichage de theta
        let label = TrigoModel.label(for: theta, unit: view.angleUnit)
        context.draw(text(label, size: 0.08 * unit, color: thetaColor),
                     at: p(0.4 * unit * cos(theta / 2), 0.4 * unit * sin(theta / 2)), anchor: .center)

        if view.sinCos {
            drawResume()
        }
    }

    private func drawCircleAndAxes() {
        // Affichage des axes
        line(from: p(-1.2 * unit, 0), to: p(1.2 * unit, 0), color: palette.gray)
        line(from: p(0, -1.2 * unit), to: p(0, 1.2 * unit), color: palette.gray)
        // Affichage des flèches
        var arrows = Path()
        arrows.addLines([p(1.2 * unit, -0.02 * unit), p(1.26 * unit, 0), p(1.2 * unit, 0.02 * unit)])
        arrows.closeSubpath()
        arrows.addLines([p(-0.02 * unit, 1.2 * unit), p(0, 1.26 * unit), p(0.02 * unit, 1.2 * unit)])
        arrows.closeSubpath()
        context.fill(arrows, with: .color(palette.gray))

        // Affichage du cercle
        context.stroke(Path(ellipseIn: CGRect(origin: p(-unit, unit), size: CGSize(width: 2 * unit, height: 2 * unit))),
                       with: .color(palette.circle))

        // Affichage des labels
        let labels: [(String, CGFloat, CGFloat)] = [
            ("0", -0.1, -0.15), ("1", 1.05, -0.15), ("-1", -1.15, -0.15), ("1", -0.1, 1.01), ("-1", -0.15, -1.15),
            ("x", 1.18, -0.15), ("y", 0.05, 1.15),
        ]
        for (string, x, y) in labels {
            context.draw(text(string, size: 0.1 * unit, color: palette.gray), at: p(x * unit, y * unit), anchor: .bottomLeading)
        }

        if view.standardAngles {
            for quarter in -2..<2 {
                for offset in [0, Double.pi / 6, Double.pi / 4, Double.pi / 3] {
                    drawRefPoint(offset + Double(quarter) * .pi / 2)
                }
            }
        }
    }

    private func drawRefPoint(_ angle: Double) {
        let x = unit * cos(angle)
        let y = unit * sin(angle)
        dot(at: p(x, y), radius: 0.012 * unit, color: palette.text)
        let label = TrigoModel.label(for: angle, unit: view.angleUnit)
        context.draw(text(label, size: 0.07 * unit, color: palette.standard, kern: 1), at: p(1.12 * x, 1.12 * y), anchor: .center)
    }

    private func drawCoordinates() {
        let x = view.model.point.x * unit
        let y = view.model.point.y * unit
        let dash = StrokeStyle(lineWidth: 1, dash: [0.05 * unit, 0.05 * unit])
        line(from: p(0, y), to: p(x, y), color: palette.text, style: dash)
        line(from: p(x, 0), to: p(x, y), color: palette.text, style: dash)

        // Affichage de x
        context.draw(text(String(format: "%1.3f", cos(theta)), size: 0.08 * unit, color: palette.text),
                     at: p(x, y >= 0 ? -0.12 * unit : 0), anchor: .bottom)
        // Affichage de y
        let yTag = text(String(format: "%1.3f", sin(theta)), size: 0.08 * unit, color: palette.text)
        if x >= 0 {
            context.draw(yTag, at: p(-0.05 * unit, y), anchor: .trailing)
        } else {
            context.draw(yTag, at: p(0.05 * unit, y), anchor: .leading)
        }
    }

    /// Encadré récapitulatif : θ, cos(θ) et sin(θ).
    private func drawResume() {
        let size = 0.08 * unit
        let font = NSFont(name: "Helvetica", size: fontSize(size)) ?? .systemFont(ofSize: fontSize(size))
        let lineHeight = 2.8 * font.xHeight
        let labelWidth = measure(text("cos(θ) = ", size: size, color: palette.text)).width
        let maxWidth = measure(text("cos(T) = 0.12345", size: size, color: palette.text)).width

        let box = CGRect(origin: p(0.97 * unit, 0.98 * unit + 3 * lineHeight + 0.04 * unit),
                         size: CGSize(width: maxWidth + 0.06 * unit, height: 3 * lineHeight + 0.04 * unit))
        context.stroke(Path(box), with: .color(palette.boxBorder))
        context.fill(Path(box), with: .color(palette.box))

        let rows: [(String, Text)] = [
            ("θ = ", text(" " + TrigoModel.label(for: theta, unit: view.angleUnit), size: size, color: palette.text)),
            ("cos(θ) = ", displayedValue(cos(theta), size: size)),
            ("sin(θ) = ", displayedValue(sin(theta), size: size)),
        ]
        // Les trois lignes sont alignées sur le signe « = » et posées sur leur ligne de base
        for (index, row) in rows.enumerated() {
            let baseline = p(unit + labelWidth, unit + 0.02 * unit + (2.5 - CGFloat(index)) * lineHeight - 0.5 * font.xHeight)
            let label = context.resolve(text(row.0, size: size, color: palette.text))
            let labelSize = label.measure(in: unbounded)
            context.draw(label, at: CGPoint(x: baseline.x - labelSize.width, y: baseline.y - label.firstBaseline(in: unbounded)),
                         anchor: .topLeading)
            let value = context.resolve(row.1)
            context.draw(value, at: CGPoint(x: baseline.x, y: baseline.y - value.firstBaseline(in: unbounded)), anchor: .topLeading)
        }
    }

    /// Valeur exacte pour les angles remarquables (1/2, √2/2, √3/2), valeur approchée sinon.
    private func displayedValue(_ value: Double, size: CGFloat) -> Text {
        let sign = text(value < -0.0001 ? TrigoModel.minus : " ", size: size, color: palette.text)
        let magnitude = abs(value)
        if abs(magnitude - 0.866) < 0.0001 {
            return sign + squareRoot(of: 3, size: size)
        } else if abs(magnitude - 0.7071) < 0.0001 {
            return sign + squareRoot(of: 2, size: size)
        } else if abs(magnitude - 0.5) < 0.0001 {
            return sign + text("1\(TrigoModel.div)2", size: size, color: palette.text)
        }
        return sign + text(String(format: "%1.3f", magnitude), size: size, color: palette.text)
    }

    /// « √n/2 » : la barre du radical est un tiret cadratin remonté et ramené au-dessus du nombre.
    private func squareRoot(of number: Int, size: CGFloat) -> Text {
        let font = NSFont(name: "Helvetica", size: fontSize(size)) ?? .systemFont(ofSize: fontSize(size))
        let bar = ("—" as NSString).size(withAttributes: [.font: font])
        func part(_ string: String, kern: CGFloat = 0, baseline: CGFloat = 0) -> Text {
            text(string, size: size, color: palette.text, kern: kern).baselineOffset(baseline)
        }
        return part("√", kern: -0.01 * bar.height)
            + part("—", kern: -0.65 * bar.height, baseline: 0.62 * bar.width)
            + part("\(number) ")
            + part(TrigoModel.div, baseline: 0.2 * bar.width)
            + part("2")
    }
}
