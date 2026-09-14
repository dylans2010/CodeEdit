import Foundation

struct GitLabTokenConfiguration: GitRouterConfiguration {

    var apiEndpoint: String?
    var accessToken: String?
    let errorDomain: String? = "com.codeedit.models.accounts.gitlab"

    init(_ token: String? = nil, url: String = GitURL.gitlabBaseURL) {
        apiEndpoint = url
        accessToken = token
    }
}

struct GitLabPrivateTokenConfiguration: GitRouterConfiguration {
    var apiEndpoint: String?
    var accessToken: String?
    let errorDomain: String? = "com.codeedit.models.accounts.gitlab"

    init(_ token: String? = nil, url: String = GitURL.gitlabBaseURL) {
        apiEndpoint = url
        accessToken = token
    }

    var accessTokenFieldName: String {
        "private_token"
    }
}
