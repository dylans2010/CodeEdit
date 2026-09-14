import Foundation

// TODO: DOCS (Nanashi Li)

class GitHubFile: Codable {
    private(set) var id: Int = -1
    var rawURL: URL?
    var filename: String?
    var type: String?
    var language: String?
    var size: Int?
    var content: String?

    enum CodingKeys: String, CodingKey {
        case rawURL = "raw_url"
        case filename
        case type
        case language
        case size
        case content
    }
}
