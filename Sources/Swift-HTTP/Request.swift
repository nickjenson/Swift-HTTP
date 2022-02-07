//
//  Request.swift
//  
//
//  Created by Nick Jenson on 2/6/22.
//

import Foundation

// Infinite number of single-word methods, using enum would limit us
public struct HTTPMethod: Hashable {
    public static let get = HTTPMethod(rawValue: "GET")
    public static let post = HTTPMethod(rawValue: "POST")
    public static let put = HTTPMethod(rawValue: "PUT")
    public static let delete = HTTPMethod(rawValue: "DELETE")
    
    public let rawValue: String
}

public struct HTTPStatus: Hashable {
    public static let ok = HTTPStatus(rawValue: 200)
    
    public static let found = HTTPStatus(rawValue: 302)
    public static let temporaryRedirect = HTTPStatus(rawValue: 307)
    
    public static let badRequest = HTTPStatus(rawValue: 400)
    public static let unauthorized = HTTPStatus(rawValue: 401)
    public static let requestTimeout = HTTPStatus(rawValue: 408)
    
    public static let internalServerError = HTTPStatus(rawValue: 500)
    
    public let rawValue: Int
}

// Represents 1. request line (method, path) 2. Headers and 3. Body
public struct HTTPRequest {
    private var urlComponents = URLComponents() // does heavy lifting of fully-formed URL handling
    public var method: HTTPMethod = .get
    public var headers: [String: String] = [:]
    public var body: HTTPBody = EmptyBody() // was optional "HTTPBody?", updated to default to EmptyBody()
    
    public init() {
        urlComponents.scheme = "https"
    }
}

// Selectively re-exposing portions of [private] urlComponents
public extension HTTPRequest {
    var scheme: String { urlComponents.scheme ?? "https" }
    
    var host: String? {
        get { urlComponents.host }
        set { urlComponents.host = newValue }
    }
    
    var path: String {
        get { urlComponents.path }
        set { urlComponents.path = newValue }
    }
}

public struct HTTPResponse {
    public let request: HTTPRequest // helpful to have request in response
    private let response: HTTPURLResponse // represents all of response _except_ body
    public let body: Data?
    
    public var status: HTTPStatus {
        HTTPStatus(rawValue: response.statusCode)
    }
    
    public var message: String {
        HTTPURLResponse.localizedString(forStatusCode: response.statusCode)
    }
    
    public var headers: [AnyHashable: Any] { response.allHeaderFields }
}

// We won't _always_ get a response, need to encapsulate those scenarios with HTTPResult
public typealias HTTPResult = Result<HTTPResponse, HTTPError>

public struct HTTPError: Error {
    // The high-level classification of error
    public let code: Code
    
    // The HTTPRequest that resulted in error
    public let request: HTTPRequest
    
    // Any HTTPResponse (partial or otherwise)
    public let response: HTTPResponse?
    
    public let underlyingError: Error?
    
    public enum Code {
        case invalidRequest
        case cannotConnect
        case cancelled
        case insecureConnection
        case invalidResponse
        // fill more in as needed later
        case unknown
    }
}

// Having an HTTPResult means we have an HTTPRequest
extension HTTPResult {
    
    public var request: HTTPRequest {
        switch self {
            case .success(let response): return response.request
            case .failure(let error): return error.request
        }
    }
    
    public var response: HTTPResponse? {
        switch self {
            case .success(let response): return response
            case .failure(let error): return error.response
        }
    }
    
}

// Protocol instead of concrete type to not restrict data construction
public protocol HTTPBody {
    // helps us avoid attempting to retrieve encoded data if there isn't any
    var isEmpty: Bool { get }
    var additionalHeaders: [String: String] { get }
    func encode() throws -> Data    // get data, optionally throw error
}

// Default implementation of HTTPBody
extension HTTPBody {
    public var isEmpty: Bool { return false }
    public var additionalHeaders: [String: String] { return [:] }
}

// Defining EmptyBody
public struct EmptyBody: HTTPBody {
    public let isEmpty = true
    
    public init() {}
    public func encode() throws -> Data { Data() }
}

public struct DataBody: HTTPBody {
    private let data: Data
    
    public var isEmpty: Bool { data.isEmpty }
    public var additionalHeaders: [String : String]
    
    public init(_ data: Data, additionalHeaders: [String: String] = [:]) {
        self.data = data
        self.additionalHeaders = additionalHeaders
    }
    
    public func encode() throws -> Data { data }
}

public struct JSONBody: HTTPBody {
    public let isEmpty: Bool = false
    public var additionalHeaders = [
        "Content-Type": "application/json; charset=utf-8"
    ]
    
    private let encoder: () throws -> Data // changed to encoder
    
    public init<T: Encodable>(_ value: T, encoder: JSONEncoder = JSONEncoder()) {
        self.encoder = { try encoder.encode(value) }
    }
    
    public func encode() throws -> Data { return try encoder() }
}

// Form body should end up as URL-encoded key-value pairs: name=Aurther&age=42
public struct FormBody: HTTPBody {
    public var isEmpty: Bool { values.isEmpty }
    public let additionalHeaders =  [
        "Content-Type": "application/x-www-form-urlencoded; charset=utf-8"
    ]
    
    private let values: [URLQueryItem]
    
    public init(_ values: [URLQueryItem]){
        self.values = values
    }
    
    public init (_ values: [String: String]) {
        let queryItems = values.map { URLQueryItem(name: $0.key, value: $0.value) }
        self.init(queryItems)
    }
    
    public func encode() throws -> Data {
        let pieces = values.map(self.urlEncode)
        let bodyString = pieces.joined(separator: "&")
        return Data(bodyString.utf8)
    }

    private func urlEncode(_ queryItem: URLQueryItem) -> String {
        let name = urlEncode(queryItem.name)
        let value = urlEncode(queryItem.value ?? "")
        return "\(name)=\(value)"
    }
    
    private func urlEncode(_ string: String) -> String {
        let allowedCharacters = CharacterSet.alphanumerics
        return string.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? ""
    }
}


