import Combine
import Foundation

// TODO: DOCS (Marco Carnevali)
extension WorkspaceClient {
    static var empty = Self(
        folderURL: { nil },
        getFiles: CurrentValueSubject<[FileItem], Never>([]).eraseToAnyPublisher(),
        getFileItem: { _ in throw WorkspaceClientError.fileNotExist }
    )
}
