import SwiftUI

struct NavigatorSidebarView: View {
    @ObservedObject
    private var workspace: WorkspaceDocument

    @State
    private var selection: Int = 0

    private let toolbarPadding: Double = -8.0

    init(workspace: WorkspaceDocument) {
        self.workspace = workspace
    }

    var body: some View {
        VStack {
            switch selection {
            case 0:
                ProjectNavigatorView()
            case 1:
                SourceControlNavigatorView()
            case 2:
                FindNavigatorView()
            case 3:
                DependenciesNavigatorView()
            case 4:
                TestsNavigatorView()
            case 5:
                IssuesNavigatorView()
            case 6:
                SymbolsNavigatorView()
            case 7:
                ExtensionNavigatorView()
            case 8:
                UtilitiesNavigatorView()
            default:
                ProjectNavigatorView()
            }
        }
        .safeAreaInset(edge: .top) {
            NavigatorSidebarToolbarTop(selection: $selection)
                .padding(.bottom, toolbarPadding)
        }
        .safeAreaInset(edge: .bottom) {
            Group {
                switch selection {
                case 0:
                    NavigatorSidebarToolbarBottom()
                case 1:
                    SourceControlToolbarBottom()
                default:
                    NavigatorSidebarToolbarBottom()
                }
            }
            .padding(.top, toolbarPadding)
        }
        .environmentObject(workspace)
    }
}
