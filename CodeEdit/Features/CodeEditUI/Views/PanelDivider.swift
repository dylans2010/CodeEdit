import SwiftUI

struct PanelDivider: View {
    @Environment(\.colorScheme)
    private var colorScheme

    var body: some View {
        Divider()
            .opacity(0)
            .overlay(
                Color(.black)
                    .opacity(colorScheme == .dark ? 0.65 : 0.13)
            )
    }
}
