import SwiftUI

@main
struct DocumentApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: TextDocument()) { file in
            ContentView(document: file.$document)
        }
    }
}

struct TextDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }
    var text: String = "Hello from {{PROJECT_NAME}}!"

    init(text: String = "Hello from {{PROJECT_NAME}}!") {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            text = String(decoding: data, as: UTF8.self)
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = Data(text.utf8)
        return .init(regularFileWithContents: data)
    }
}

struct ContentView: View {
    @Binding var document: TextDocument

    var body: some View {
        TextEditor(text: $document.text)
            .padding()
    }
}
