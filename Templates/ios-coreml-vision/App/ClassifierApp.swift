import SwiftUI

@main
struct ClassifierApp: App {
    var body: some Scene {
        WindowGroup {
            ClassifierView()
        }
    }
}

struct ClassifierView: View {
    @State private var classificationResult = "Ready to classify image..."

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "viewfinder")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)
            Text("{{PROJECT_NAME}} Vision ML")
                .font(.title2)
                .bold()
            Text(classificationResult)
                .foregroundColor(.secondary)
            Button("Run Inference") {
                classificationResult = "Detected: Neural Network Object (98%)"
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
