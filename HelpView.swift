import SwiftUI

/// Fenêtre d'aide : affiche le `ReadMe.rtf` localisé du bundle.
struct HelpView: View {
    var url = Bundle.main.url(forResource: "ReadMe", withExtension: "rtf")

    var body: some View {
        RichTextView(url: url)
            .frame(minWidth: 420, minHeight: 300)
    }
}

/// Vue de texte AppKit en lecture seule : SwiftUI ne sait pas afficher fidèlement un fichier RTF.
private struct RichTextView: NSViewRepresentable {
    let url: URL?

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else { return scrollView }
        textView.isEditable = false
        textView.isSelectable = true
        textView.textContainerInset = NSSize(width: 16, height: 16)
        // Le texte du RTF est noir : le système l'éclaircit en mode sombre
        textView.usesAdaptiveColorMappingForDarkAppearance = true

        if let url, let text = try? NSMutableAttributedString(url: url, options: [:], documentAttributes: nil) {
            Self.addLinks(to: text)
            textView.textStorage?.setAttributedString(text)
        }
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {}

    /// Rend cliquables les adresses « https://… » du texte.
    private static func addLinks(to text: NSMutableAttributedString) {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else { return }
        let string = text.string as NSString
        for match in detector.matches(in: text.string, range: NSRange(location: 0, length: string.length)) {
            guard let link = match.url, string.substring(with: match.range).hasPrefix("https://") else { continue }
            text.addAttribute(.link, value: link, range: match.range)
        }
    }
}
