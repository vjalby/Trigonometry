import SwiftUI

@main
struct TrigonometryApp: App {
    @StateObject private var model = TrigoModel()
    @AppStorage("prefs_angleUnit") private var angleUnit = AngleUnit.radian.rawValue
    @AppStorage("prefs_standardAngles") private var standardAngles = false
    @AppStorage("prefs_sinCos") private var sinCos = false

    var body: some Scene {
        Window("Trigonometry", id: "trigoWindow") {
            ContentView(model: model)
        }
        .defaultSize(width: 480, height: 345)
        .commands {
            CommandGroup(replacing: .printItem) {
                Button("Page Setup…") {
                    NSApp.runPageLayout(nil)
                }
                .keyboardShortcut("p", modifiers: [.command, .shift])
                Button("Print…") {
                    printDiagram(model: model,
                                 angleUnit: AngleUnit(rawValue: angleUnit) ?? .radian,
                                 standardAngles: standardAngles,
                                 sinCos: sinCos)
                }
                .keyboardShortcut("p")
            }
            CommandGroup(replacing: .help) {
                Button("Trigonometry Help") {
                    if let url = Bundle.main.url(forResource: "ReadMe", withExtension: "rtf") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .keyboardShortcut("?")
            }
        }
    }
}
