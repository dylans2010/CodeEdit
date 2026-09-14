import Foundation

// TODO: DOCS (Pavel Kasila)
struct APIResponse<T> {
    let value: T
    let response: URLResponse
}
