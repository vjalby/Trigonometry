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
        .defaultSize(width: 671, height: 380)
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
                HelpCommand()
            }
        }

        Window("Trigonometry Help", id: "helpWindow") {
            HelpView()
        }
        .defaultSize(width: 560, height: 620)
    }
}

/// The Help menu item; a separate view, because `openWindow` is read from the environment.
private struct HelpCommand: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Trigonometry Help") {
            openWindow(id: "helpWindow")
        }
        .keyboardShortcut("?")
    }
}
