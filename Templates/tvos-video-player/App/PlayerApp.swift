import SwiftUI
import AVKit

@main
struct PlayerApp: App {
    var body: some Scene {
        WindowGroup {
            VStack {
                Text("{{PROJECT_NAME}} Player")
                    .font(.largeTitle)
                VideoPlayer(player: AVPlayer(url: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")!))
                    .frame(height: 540)
            }
        }
    }
}
