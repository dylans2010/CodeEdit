import Foundation

class GitLabAvatarURL: Codable {
    var url: URL?

    init(_ json: [String: AnyObject]) {
        if let urlString = json["url"] as? String, let urlFromString = URL(string: urlString) {
            url = urlFromString
        }
    }
}
