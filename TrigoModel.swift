import AppKit
import Combine

enum AngleUnit: Int {
    case radian = 0
    case degree = 1
}

/// State of the unit circle: the current angle and the matching point M.
final class TrigoModel: ObservableObject {
    @Published private(set) var theta: Double = 0
    @Published private(set) var point = CGPoint(x: 1, y: 0)
    @Published private(set) var isDragging = false

    /// The current gesture started off the circle: it is ignored until the mouse is released.
    private var rejected = false

    // MARK: Mouse

    /// `location` is expressed in the circle's coordinate system (radius 1, origin at the center).
    func drag(to location: CGPoint) {
        if isDragging {
            process(location)
            return
        }
        if rejected { return }
        let norm2 = location.x * location.x + location.y * location.y
        guard norm2 > 0.9 && norm2 < 1.1 else {
            NSSound.beep()
            rejected = true
            return
        }
        process(location)
        if abs(theta) > 6.28 { // clicking on 0 forces theta = 0 (rather than 2π)
            theta = 0
            process(location)
        }
        isDragging = true
    }

    func endDrag() {
        isDragging = false
        rejected = false
    }

    private func process(_ location: CGPoint) {
        let newTheta = atan2(location.y, location.x)
        if newTheta < 0 && theta > 0 {
            theta = newTheta + 2 * .pi
        } else if newTheta > 0 && theta < 0 {
            theta = newTheta - 2 * .pi
        } else {
            theta = newTheta
        }
        theta = Self.normalize(theta).angle
        point = CGPoint(x: copysign(cos(theta), location.x), y: copysign(sin(theta), location.y))
    }

    // MARK: Standard angles

    static let minus = "−"
    static let div = "∕"
    /// Thin space, placed between the minus sign and a digit.
    static let thinSpace = "\u{2009}"

    /// Decimal notation using the separator chosen in macOS settings (0.33 or 0,33)
    /// and a true minus sign, set off from the number by a thin space.
    static func decimal(_ value: Double, digits: Int) -> String {
        (value < 0 ? minus + thinSpace : "") + String(format: "%.\(digits)f", locale: .current, abs(value))
    }

    /// Snaps the angle to the nearest multiple of π, π/2, π/3, π/4 or π/6 (within 0.075 rad)
    /// and returns its notation in radians.
    static func normalize(_ angle: Double) -> (angle: Double, label: String) {
        for fraction in [1, 2, 3, 4, 6] {
            if let result = normalize(angle, fraction: fraction) { return result }
        }
        return (angle, decimal(angle, digits: 2))
    }

    private static func normalize(_ angle: Double, fraction: Int) -> (angle: Double, label: String)? {
        let multiple = Int((Double(fraction) * angle / .pi).rounded())
        let snapped = Double(multiple) * .pi / Double(fraction)
        guard abs(angle - snapped) < 0.075 else { return nil }

        let fractionString = fraction == 1 ? "" : "\(div)\(fraction)"
        switch multiple {
        case 0: return (snapped, "0")
        case 1: return (snapped, "π\(fractionString)")
        case -1: return (snapped, "\(minus)π\(fractionString)")
        case ..<0: return (snapped, "\(minus)\(-multiple)π\(fractionString)")
        default: return (snapped, "\(multiple)π\(fractionString)")
        }
    }

    /// Notation of the angle in the chosen unit.
    static func label(for angle: Double, unit: AngleUnit) -> String {
        let normalized = normalize(angle)
        switch unit {
        case .radian: return normalized.label
        case .degree: return decimal(normalized.angle * 180 / .pi, digits: 0) + "°"
        }
    }
}
