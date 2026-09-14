import Foundation

class GitLabGroupAccess: Codable {
    var accessLevel: Int?
    var notificationLevel: Int?

    init(_ json: [String: AnyObject]) {
        accessLevel = json["access_level"] as? Int
        notificationLevel = json["notification_level"] as? Int
    }
}
