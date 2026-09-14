// swiftlint:disable file_length type_body_length function_body_length cyclomatic_complexity line_length
import SwiftUI
import WebKit
import Combine

// MARK: - Markdown Editor View
struct MarkdownEditorView: View {
    @ObservedObject var codeFile: CodeFileDocument
    let fileItem: WorkspaceClient.FileItem

    enum DisplayMode: String, CaseIterable, Identifiable {
        case split = "Split"
        case editor = "Editor"
        case preview = "Preview"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .split: return "rectangle.split.2x1"
            case .editor: return "square.and.pencil"
            case .preview: return "eye"
            }
        }
    }

    @State private var mode: DisplayMode = .split
    @State private var textSelection: NSRange = NSRange(location: 0, length: 0)
    @State private var cancellables = Set<AnyCancellable>()

    var body: some View {
        VStack(spacing: 0) {
            BreadcrumbsView(file: fileItem, tappedOpenFile: { _ in })
            Divider()
            markdownToolbar
            Divider()

            GeometryReader { proxy in
                HStack(spacing: 0) {
                    if mode == .split || mode == .editor {
                        editorPane
                            .frame(width: mode == .split ? proxy.size.width / 2 : proxy.size.width)
                    }

                    if mode == .split {
                        Divider()
                    }

                    if mode == .split || mode == .preview {
                        previewPane
                            .frame(width: mode == .split ? proxy.size.width / 2 : proxy.size.width)
                    }
                }
            }
        }
        .onAppear {
            setupAutosave()
        }
    }

    private func setupAutosave() {
        codeFile.$content
            .dropFirst()
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .sink { _ in
                codeFile.updateChangeCount(.changeDone)
                codeFile.autosave(withImplicitCancellability: false) { _ in }
            }
            .store(in: &cancellables)
    }

    // MARK: - Toolbar
    private var markdownToolbar: some View {
        HStack(spacing: 4) {
            // Mode selector
            Picker("", selection: $mode) {
                ForEach(DisplayMode.allCases) { modeItem in
                    Label(modeItem.rawValue, systemImage: modeItem.icon).tag(modeItem)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 210)
            .padding(.trailing, 8)

            Divider().frame(height: 18)

            // Headings
            Menu {
                Button("Heading 1 (#)") { insertFormat(prefix: "# ", suffix: "") }
                Button("Heading 2 (##)") { insertFormat(prefix: "## ", suffix: "") }
                Button("Heading 3 (###)") { insertFormat(prefix: "### ", suffix: "") }
                Button("Heading 4 (####)") { insertFormat(prefix: "#### ", suffix: "") }
            } label: {
                Label("Headings", systemImage: "textformat.size")
                    .font(.system(size: 11))
            }
            .menuStyle(.borderlessButton)
            .frame(width: 32)
            .help("Headings")

            // Inline styles
            toolbarButton(icon: "bold", tooltip: "Bold (**text**)") {
                insertFormat(prefix: "**", suffix: "**", placeholder: "bold text")
            }
            toolbarButton(icon: "italic", tooltip: "Italic (*text*)") {
                insertFormat(prefix: "*", suffix: "*", placeholder: "italic text")
            }
            toolbarButton(icon: "strikethrough", tooltip: "Strikethrough (~~text~~)") {
                insertFormat(prefix: "~~", suffix: "~~", placeholder: "strikethrough text")
            }
            toolbarButton(icon: "curlybraces", tooltip: "Inline Code (`code`)") {
                insertFormat(prefix: "`", suffix: "`", placeholder: "code")
            }

            Divider().frame(height: 18)

            // Lists & Blocks
            toolbarButton(icon: "list.bullet", tooltip: "Bulleted List") {
                insertFormat(prefix: "- ", suffix: "", placeholder: "List item")
            }
            toolbarButton(icon: "list.number", tooltip: "Numbered List") {
                insertFormat(prefix: "1. ", suffix: "", placeholder: "List item")
            }
            toolbarButton(icon: "checklist", tooltip: "Task / Checklist") {
                insertFormat(prefix: "- [ ] ", suffix: "", placeholder: "Task item")
            }
            toolbarButton(icon: "text.quote", tooltip: "Blockquote") {
                insertFormat(prefix: "> ", suffix: "", placeholder: "Quote")
            }
            toolbarButton(icon: "chevron.left.forwardslash.chevron.right", tooltip: "Code Block") {
                insertFormat(prefix: "```swift\n", suffix: "\n```\n", placeholder: "// Code block here")
            }

            Divider().frame(height: 18)

            // Media & Table
            toolbarButton(icon: "link", tooltip: "Link") {
                insertFormat(prefix: "[", suffix: "](https://example.com)", placeholder: "link text")
            }
            toolbarButton(icon: "photo", tooltip: "Image") {
                insertFormat(prefix: "![", suffix: "](https://example.com/image.png)", placeholder: "alt text")
            }
            toolbarButton(icon: "tablecells", tooltip: "Table") {
                insertTable()
            }
            toolbarButton(icon: "minus", tooltip: "Horizontal Rule") {
                insertFormat(prefix: "\n---\n", suffix: "", placeholder: "")
            }

            Spacer()

            Text("\(codeFile.content.components(separatedBy: .newlines).count) lines")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.secondary)
                .padding(.trailing, 8)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func toolbarButton(icon: String, tooltip: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .frame(width: 24, height: 22)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(tooltip)
    }

    // MARK: - Editor Pane
    private var editorPane: some View {
        MarkdownEditorTextView(text: $codeFile.content)
            .background(Color(nsColor: .textBackgroundColor))
    }

    // MARK: - Preview Pane
    private var previewPane: some View {
        MarkdownPreviewView(markdown: codeFile.content)
            .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Formatting Helpers
    private func insertFormat(prefix: String, suffix: String, placeholder: String = "") {
        let insertContent = placeholder.isEmpty ? "\(prefix)\(suffix)" : "\(prefix)\(placeholder)\(suffix)"
        codeFile.content.append(insertContent)
        codeFile.updateChangeCount(.changeDone)
    }

    private func insertTable() {
        let tableMarkdown = """

| Column 1 | Column 2 | Column 3 |
| :--- | :---: | ---: |
| Item 1 | Center | Right |
| Item 2 | Center | Right |

"""
        codeFile.content.append(tableMarkdown)
        codeFile.updateChangeCount(.changeDone)
    }
}

// MARK: - Markdown Editor Text View (AppKit wrapper with font & styling)
private struct MarkdownEditorTextView: NSViewRepresentable {
    @Binding var text: String

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else { return scrollView }

        textView.delegate = context.coordinator
        textView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.isRichText = false
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.textContainerInset = NSSize(width: 12, height: 12)
        textView.drawsBackground = true
        textView.backgroundColor = .textBackgroundColor
        textView.string = text

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        if textView.string != text {
            let selectedRanges = textView.selectedRanges
            textView.string = text
            textView.selectedRanges = selectedRanges
        }
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MarkdownEditorTextView

        init(_ parent: MarkdownEditorTextView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            self.parent.text = textView.string
        }
    }
}

// MARK: - Full Markdown Preview View (WKWebView Renderer)
struct MarkdownPreviewView: NSViewRepresentable {
    let markdown: String

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let html = generateHTML(from: markdown)
        webView.loadHTMLString(html, baseURL: nil)
    }

    private func generateHTML(from markdown: String) -> String {
        let parsedBody = MarkdownParser.html(from: markdown)

        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <style>
                :root {
                    color-scheme: light dark;
                }
                body {
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
                    font-size: 14px;
                    line-height: 1.6;
                    padding: 24px 32px;
                    margin: 0;
                    color: #24292f;
                    background-color: transparent;
                }
                @media (prefers-color-scheme: dark) {
                    body {
                        color: #c9d1d9;
                    }
                    hr {
                        background-color: #30363d !important;
                    }
                    blockquote {
                        border-left-color: #30363d !important;
                        color: #8b949e !important;
                    }
                    table th, table td {
                        border-color: #30363d !important;
                    }
                    table tr:nth-child(2n) {
                        background-color: rgba(110, 118, 129, 0.1) !important;
                    }
                    code, pre {
                        background-color: #161b22 !important;
                    }
                }
                h1, h2, h3, h4, h5, h6 {
                    margin-top: 24px;
                    margin-bottom: 16px;
                    font-weight: 600;
                    line-height: 1.25;
                }
                h1 {
                    font-size: 2em;
                    padding-bottom: 0.3em;
                    border-bottom: 1px solid rgba(120, 120, 120, 0.2);
                }
                h2 {
                    font-size: 1.5em;
                    padding-bottom: 0.3em;
                    border-bottom: 1px solid rgba(120, 120, 120, 0.2);
                }
                h3 { font-size: 1.25em; }
                p, blockquote, ul, ol, dl, table, pre {
                    margin-top: 0;
                    margin-bottom: 16px;
                }
                a {
                    color: #0969da;
                    text-decoration: none;
                }
                a:hover {
                    text-decoration: underline;
                }
                hr {
                    height: 2px;
                    padding: 0;
                    margin: 24px 0;
                    background-color: #d0d7de;
                    border: 0;
                }
                blockquote {
                    padding: 0 1em;
                    color: #57606a;
                    border-left: 0.25em solid #d0d7de;
                }
                ul, ol {
                    padding-left: 2em;
                }
                li {
                    margin-top: 0.25em;
                }
                table {
                    border-spacing: 0;
                    border-collapse: collapse;
                    margin-top: 0;
                    margin-bottom: 16px;
                    width: 100%;
                    overflow: auto;
                }
                table th {
                    font-weight: 600;
                    padding: 6px 13px;
                    border: 1px solid #d0d7de;
                    background-color: rgba(120, 120, 120, 0.1);
                }
                table td {
                    padding: 6px 13px;
                    border: 1px solid #d0d7de;
                }
                table tr:nth-child(2n) {
                    background-color: rgba(120, 120, 120, 0.05);
                }
                code {
                    padding: 0.2em 0.4em;
                    margin: 0;
                    font-size: 85%;
                    background-color: rgba(175, 184, 193, 0.2);
                    border-radius: 6px;
                    font-family: ui-monospace, SFMono-Regular, "SF Mono", Menlo, Consolas, monospace;
                }
                pre {
                    padding: 16px;
                    overflow: auto;
                    font-size: 85%;
                    line-height: 1.45;
                    background-color: #f6f8fa;
                    border-radius: 6px;
                }
                pre code {
                    background-color: transparent;
                    padding: 0;
                    margin: 0;
                    font-size: 100%;
                    border-radius: 0;
                }
                input[type="checkbox"] {
                    margin-right: 0.5em;
                }
                img {
                    max-width: 100%;
                    box-sizing: content-box;
                    border-radius: 6px;
                }
            </style>
        </head>
        <body>
            \(parsedBody)
        </body>
        </html>
        """
    }
}

// MARK: - Markdown Parser Engine
private enum MarkdownParser {
    static func html(from markdown: String) -> String {
        var lines = markdown.components(separatedBy: "\n")
        var result: [String] = []
        var inCodeBlock = false
        var codeBlockLang = ""
        var codeBlockContent = ""
        var inList = false
        var listTag = "ul"
        var inTable = false
        var tableContent: [String] = []

        func flushList() {
            if inList {
                result.append("</\(listTag)>")
                inList = false
            }
        }

        func flushTable() {
            if inTable && !tableContent.isEmpty {
                result.append("<table>")
                for (index, row) in tableContent.enumerated() {
                    let cols = row.split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                    if index == 0 {
                        result.append("<thead><tr>")
                        for col in cols {
                            result.append("<th>\(col)</th>")
                        }
                        result.append("</tr></thead><tbody>")
                    } else if index == 1 && row.contains("-") {
                        // Header separator row, skip
                        continue
                    } else {
                        result.append("<tr>")
                        for col in cols {
                            result.append("<td>\(col)</td>")
                        }
                        result.append("</tr>")
                    }
                }
                result.append("</tbody></table>")
                inTable = false
                tableContent.removeAll()
            }
        }

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Code block handling
            if trimmed.hasPrefix("```") {
                if inCodeBlock {
                    let escaped = escapeHTML(codeBlockContent)
                    result.append("<pre><code class=\"language-\(codeBlockLang)\">\(escaped)</code></pre>")
                    inCodeBlock = false
                    codeBlockContent = ""
                } else {
                    flushList()
                    flushTable()
                    inCodeBlock = true
                    codeBlockLang = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                }
                continue
            }

            if inCodeBlock {
                codeBlockContent += line + "\n"
                continue
            }

            // Table rows
            if trimmed.hasPrefix("|") && trimmed.hasSuffix("|") {
                flushList()
                inTable = true
                tableContent.append(trimmed)
                continue
            } else if inTable {
                flushTable()
            }

            // Empty lines
            if trimmed.isEmpty {
                flushList()
                continue
            }

            // Horizontal Rule
            if trimmed == "---" || trimmed == "***" || trimmed == "___" {
                flushList()
                result.append("<hr>")
                continue
            }

            // Headings
            if trimmed.hasPrefix("#") {
                flushList()
                if trimmed.hasPrefix("###### ") {
                    result.append("<h6>\(parseInline(String(trimmed.dropFirst(7))))</h6>")
                } else if trimmed.hasPrefix("##### ") {
                    result.append("<h5>\(parseInline(String(trimmed.dropFirst(6))))</h5>")
                } else if trimmed.hasPrefix("#### ") {
                    result.append("<h4>\(parseInline(String(trimmed.dropFirst(5))))</h4>")
                } else if trimmed.hasPrefix("### ") {
                    result.append("<h3>\(parseInline(String(trimmed.dropFirst(4))))</h3>")
                } else if trimmed.hasPrefix("## ") {
                    result.append("<h2>\(parseInline(String(trimmed.dropFirst(3))))</h2>")
                } else if trimmed.hasPrefix("# ") {
                    result.append("<h1>\(parseInline(String(trimmed.dropFirst(2))))</h1>")
                }
                continue
            }

            // Blockquote
            if trimmed.hasPrefix("> ") {
                flushList()
                result.append("<blockquote><p>\(parseInline(String(trimmed.dropFirst(2))))</p></blockquote>")
                continue
            }

            // Task list checkbox
            if trimmed.hasPrefix("- [ ] ") || trimmed.hasPrefix("* [ ] ") {
                if !inList {
                    inList = true
                    listTag = "ul"
                    result.append("<ul style=\"list-style: none; padding-left: 0;\">")
                }
                let content = String(trimmed.dropFirst(6))
                result.append("<li><input type=\"checkbox\" disabled> \(parseInline(content))</li>")
                continue
            }

            if trimmed.hasPrefix("- [x] ") || trimmed.hasPrefix("* [x] ") || trimmed.hasPrefix("- [X] ") || trimmed.hasPrefix("* [X] ") {
                if !inList {
                    inList = true
                    listTag = "ul"
                    result.append("<ul style=\"list-style: none; padding-left: 0;\">")
                }
                let content = String(trimmed.dropFirst(6))
                result.append("<li><input type=\"checkbox\" checked disabled> \(parseInline(content))</li>")
                continue
            }

            // Bullet list
            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("+ ") {
                if !inList || listTag != "ul" {
                    flushList()
                    inList = true
                    listTag = "ul"
                    result.append("<ul>")
                }
                result.append("<li>\(parseInline(String(trimmed.dropFirst(2))))</li>")
                continue
            }

            // Numbered list
            if let match = trimmed.range(of: #"^\d+\.\s+"#, options: .regularExpression) {
                if !inList || listTag != "ol" {
                    flushList()
                    inList = true
                    listTag = "ol"
                    result.append("<ol>")
                }
                let content = String(trimmed[match.upperBound...])
                result.append("<li>\(parseInline(content))</li>")
                continue
            }

            // Regular paragraph
            flushList()
            result.append("<p>\(parseInline(line))</p>")
        }

        flushList()
        flushTable()

        return result.joined(separator: "\n")
    }

    private static func parseInline(_ text: String) -> String {
        var output = escapeHTML(text)

        // Images: ![alt](url)
        output = output.replacingOccurrences(
            of: #"!\[(.*?)\]\((.*?)\)"#,
            with: "<img src=\"$2\" alt=\"$1\">",
            options: .regularExpression
        )

        // Links: [title](url)
        output = output.replacingOccurrences(
            of: #"\[(.*?)\]\((.*?)\)"#,
            with: "<a href=\"$2\">$1</a>",
            options: .regularExpression
        )

        // Bold: **text** or __text__
        output = output.replacingOccurrences(
            of: #"\*\*(.*?)\*\*"#,
            with: "<strong>$1</strong>",
            options: .regularExpression
        )

        // Italic: *text* or _text_
        output = output.replacingOccurrences(
            of: #"\*(.*?)\*"#,
            with: "<em>$1</em>",
            options: .regularExpression
        )

        // Strikethrough: ~~text~~
        output = output.replacingOccurrences(
            of: #"~~(.*?)~~"#,
            with: "<del>$1</del>",
            options: .regularExpression
        )

        // Inline Code: `code`
        output = output.replacingOccurrences(
            of: #"`(.*?)`"#,
            with: "<code>$1</code>",
            options: .regularExpression
        )

        return output
    }

    private static func escapeHTML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
