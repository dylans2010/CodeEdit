import Foundation

// TODO: DOCS (Nanashi Li)

struct GitLabAccount {
    let configuration: GitRouterConfiguration

    init(_ config: GitRouterConfiguration = GitLabTokenConfiguration()) {
        configuration = config
    }
}
