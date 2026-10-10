import SwiftUI

struct ContentView: View {
    @ObservedObject var model: TrigoModel
    @AppStorage("prefs_angleUnit") private var angleUnit = AngleUnit.radian.rawValue
    @AppStorage("prefs_standardAngles") private var standardAngles = false
    @AppStorage("prefs_sinCos") private var sinCos = false

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                TrigoView(model: model,
                          angleUnit: AngleUnit(rawValue: angleUnit) ?? .radian,
                          standardAngles: standardAngles,
                          sinCos: sinCos)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { model.drag(to: TrigoView.unitPoint($0.location, in: geometry.size)) }
                            .onEnded { _ in model.endDrag() }
                    )
            }
            .frame(minWidth: 400, minHeight: 281)

            HStack(spacing: 14) {
                Picker("Unit:", selection: $angleUnit) {
                    Text("Radians").tag(AngleUnit.radian.rawValue)
                    Text("Degrees").tag(AngleUnit.degree.rawValue)
                }
                .pickerStyle(.radioGroup)
                .horizontalRadioGroupLayout()
                .fixedSize()
                Toggle("Show standard angles", isOn: $standardAngles)
                Toggle("Show sin/cos", isOn: $sinCos)
                Spacer(minLength: 0)
            }
            .controlSize(.small)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 10)
            .padding(.vertical, 11)
        }
    }
}

// MARK: - Impression

/// Vue AppKit qui trace le dessin SwiftUI (en vectoriel) dans le contexte d'impression.
final class TrigoPrintView: NSView {
    private let render: (CGContext) -> Void

    init(frame: NSRect, render: @escaping (CGContext) -> Void) {
        self.render = render
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        render(context)
    }
}

@MainActor
func makePrintView(model: TrigoModel, angleUnit: AngleUnit, standardAngles: Bool, sinCos: Bool, size: CGSize) -> TrigoPrintView {
    let content = TrigoView(model: model, angleUnit: angleUnit, standardAngles: standardAngles, sinCos: sinCos, printing: true)
        .frame(width: size.width, height: size.height)
        .environment(\.colorScheme, .light)
    let renderer = ImageRenderer(content: content)
    return TrigoPrintView(frame: NSRect(origin: .zero, size: size)) { context in
        renderer.render { _, draw in draw(context) }
    }
}

@MainActor
func printDiagram(model: TrigoModel, angleUnit: AngleUnit, standardAngles: Bool, sinCos: Bool) {
    let printInfo = NSPrintInfo.shared
    printInfo.topMargin = 33
    printInfo.bottomMargin = 33
    printInfo.leftMargin = 33
    printInfo.rightMargin = 33
    printInfo.isHorizontallyCentered = true
    printInfo.isVerticallyCentered = true

    let size = CGSize(width: printInfo.paperSize.width - printInfo.leftMargin - printInfo.rightMargin,
                      height: printInfo.paperSize.height - printInfo.topMargin - printInfo.bottomMargin)
    let printView = makePrintView(model: model, angleUnit: angleUnit, standardAngles: standardAngles, sinCos: sinCos, size: size)
    let operation = NSPrintOperation(view: printView, printInfo: printInfo)
    if let window = NSApp.keyWindow ?? NSApp.mainWindow {
        operation.runModal(for: window, delegate: nil, didRun: nil, contextInfo: nil)
    } else {
        operation.run()
    }
}
