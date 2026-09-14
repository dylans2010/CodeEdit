import Foundation

// TODO: DOCS (Nanashi Li)

struct GitHubAccount {
    let configuration: GitHubTokenConfiguration

    init(_ config: GitHubTokenConfiguration = GitHubTokenConfiguration()) {
        configuration = config
    }
}
