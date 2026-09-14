import Foundation
import Combine

class WorkspaceNotificationModel: ObservableObject {
    init() {
        highlightedFileItem = nil
    }

    @Published var highlightedFileItem: WorkspaceClient.FileItem?
}
