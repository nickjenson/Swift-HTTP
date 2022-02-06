//
//  Request.swift
//  
//
//  Created by Nick Jenson on 2/6/22.
//

import Foundation

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

public struct HTTPRequest {
    private var urlComponents = URLComponents()
    public var method: HTTPMethod = .get // defined above
    public var headers: [String: String] = [:]
    public var body: Data?
    
    public init() {
        urlComponents.scheme = "https"
    }
}

public extension HTTPRequest {
    public var scheme: String { urlComponents.scheme ?? "https" }
    
    public var host: String? {
        get { urlComponents.host }
        set { urlComponents.host = newValue }
    }
    
    public var path: String {
        get { urlComponents.path }
        set { urlComponents.path = newValue }
    }
}

public struct HTTPResponse {
    public let request: HTTPRequest // helpful to have request in response
    private let response: HTTPURLResponse
    public let body: Data?
    
    public var status: HTTPStatus {
        HTTPStatus(rawValue: response.statusCode)
    }
    
    public var message: String {
        HTTPURLResponse.localizedString(forStatusCode: response.statusCode)
    }
    
    public var headers: [AnyHashable: Any] { response.allHeaderFields }
}

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
