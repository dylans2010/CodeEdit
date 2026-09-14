import WidgetKit
import SwiftUI

struct ComplicationView: View {
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            Gauge(value: 0.75) {
                Image(systemName: "bolt.fill")
            }
            .gaugeStyle(.accessoryCircularCapacity)
        default:
            Text("{{PROJECT_NAME}}")
        }
    }
}
