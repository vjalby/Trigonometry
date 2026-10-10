import SwiftUI

/// Help window: displays the localized `ReadMe.rtf` from the bundle.
struct HelpView: View {
    var url = Bundle.main.url(forResource: "ReadMe", withExtension: "rtf")

    var body: some View {
        RichTextView(url: url)
            .frame(minWidth: 420, minHeight: 300)
    }
}

/// Read-only AppKit text view: SwiftUI cannot render an RTF file faithfully.
private struct RichTextView: NSViewRepresentable {
    let url: URL?

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else { return scrollView }
        textView.isEditable = false
        textView.isSelectable = true
        textView.textContainerInset = NSSize(width: 16, height: 16)
        // The RTF text is black: the system lightens it in Dark Mode
        textView.usesAdaptiveColorMappingForDarkAppearance = true

        if let url, let text = try? NSMutableAttributedString(url: url, options: [:], documentAttributes: nil) {
            Self.addLinks(to: text)
            textView.textStorage?.setAttributedString(text)
        }
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {}

    /// Makes the "https://…" addresses in the text clickable.
    private static func addLinks(to text: NSMutableAttributedString) {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else { return }
        let string = text.string as NSString
        for match in detector.matches(in: text.string, range: NSRange(location: 0, length: string.length)) {
            guard let link = match.url, string.substring(with: match.range).hasPrefix("https://") else { continue }
            text.addAttribute(.link, value: link, range: match.range)
        }
    }
}
