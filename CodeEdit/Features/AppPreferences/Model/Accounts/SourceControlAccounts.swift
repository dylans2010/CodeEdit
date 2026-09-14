import Foundation

struct SourceControlAccounts: Codable, Identifiable, Hashable {
    var id: String
    var gitProvider: String
    var gitProviderLink: String
    var gitProviderDescription: String
    var gitAccountName: String
    // If bool we use the HTTP protocol else if false we use SHH
    var gitCloningProtocol: Bool
    var gitSSHKey: String
    var isTokenValid: Bool
}
