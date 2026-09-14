import Foundation

struct APIPage<T: Codable>: Codable {
    var items: [T]

    var metadata: Metadata

    struct Metadata: Codable {
        var total: Int
        var per: Int
        var page: Int
    }
}
