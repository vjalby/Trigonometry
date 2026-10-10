import SwiftUI

struct ContentView: View {
    @ObservedObject var model: TrigoModel
    @AppStorage("prefs_angleUnit") private var angleUnit = AngleUnit.radian.rawValue
    @AppStorage("prefs_standardAngles") private var standardAngles = false
    @AppStorage("prefs_sinCos") private var sinCos = false

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 0) {
            GeometryReader { geometry in
                TrigoView(model: model,
                          angleUnit: unit,
                          standardAngles: standardAngles,
                          sinCos: sinCos)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { model.drag(to: TrigoView.unitPoint($0.location, in: geometry.size)) }
                            .onEnded { _ in model.endDrag() }
                    )
            }
            .frame(minWidth: 400, minHeight: 300)

            Divider()

            // Panneau latéral : réglages et valeurs
            VStack(alignment: .leading, spacing: 16) {
                section("Unit") {
                    Picker("Unit", selection: $angleUnit) {
                        Text("Radians").tag(AngleUnit.radian.rawValue)
                        Text("Degrees").tag(AngleUnit.degree.rawValue)
                    }
                    .pickerStyle(.radioGroup)
                    .labelsHidden()
                }
                section("Display") {
                    Toggle("Standard angles", isOn: $standardAngles)
                    Toggle("sin/cos on the graph", isOn: $sinCos)
                }
                Divider()
                section("Values") {
                    TrigoValuesView(model: model, angleUnit: unit)
                }
                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(width: 190)
            .background(Color(white: colorScheme == .dark ? 0.17 : 0.95)) // gris très clair (sombre en mode sombre)
        }
    }

    private var unit: AngleUnit { AngleUnit(rawValue: angleUnit) ?? .radian }

    private func section<Content: View>(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            content()
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
    // La zone imprimable de l'imprimante peut être plus petite que la page moins les marges :
    // sans ajustement, le dessin déborde sur une seconde page vide.
    printInfo.horizontalPagination = .fit
    printInfo.verticalPagination = .fit

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
