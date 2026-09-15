import SwiftUI

struct StatusBarIndentSelector: View {

    @StateObject
    private var prefs: AppPreferencesModel = .shared

    var body: some View {
        Menu {
            Picker("Tab Width", selection: $prefs.preferences.textEditing.defaultTabWidth) {
                ForEach(2..<9) { index in
                    Text("\(index) Spaces")
                        .tag(index)
                }
            }
        } label: {
            StatusBarMenuLabel("\(prefs.preferences.textEditing.defaultTabWidth) Spaces")
        }
        .menuIndicator(.hidden)
        .menuStyle(.borderlessButton)
        .fixedSize()
        .onHover { isHovering($0) }
    }
}
