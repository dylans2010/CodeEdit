import SwiftUI

struct ContentView: View {
    @FocusState private var focusedIndex: Int?

    var body: some View {
        VStack(spacing: 40) {
            Text("{{PROJECT_NAME}} on tvOS")
                .font(.largeTitle)
            HStack(spacing: 30) {
                ForEach(0..<4) { index in
                    Button(action: { print("Selected \(index)") }) {
                        VStack {
                            Image(systemName: "film")
                                .font(.system(size: 48))
                            Text("Channel \(index + 1)")
                        }
                        .frame(width: 200, height: 160)
                    }
                    .focused($focusedIndex, equals: index)
                }
            }
        }
    }
}
