import Foundation

struct PluginRelease: Codable, Hashable, Identifiable {
    var id: UUID
    var externalID: String
    var version: String
    var tarball: URL?
}
