import WidgetKit
import SwiftUI

struct SimpleEntry: TimelineEntry {
    let date: Date
    let value: String
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), value: "{{PROJECT_NAME}}")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(SimpleEntry(date: Date(), value: "Active"))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let entry = SimpleEntry(date: Date(), value: "Updated")
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(3600)))
        completion(timeline)
    }
}

struct WidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("{{PROJECT_NAME}}")
                .font(.caption)
                .bold()
            Text(entry.value)
                .font(.title3)
        }
        .padding()
    }
}

@main
struct {{PROJECT_NAME}}WidgetBundle: WidgetBundle {
    var body: some Widget {
        {{PROJECT_NAME}}Widget()
    }
}

struct {{PROJECT_NAME}}Widget: Widget {
    let kind: String = "{{PROJECT_NAME}}Widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("{{PROJECT_NAME}} Widget")
        .description("{{APP_DESCRIPTION}}")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
