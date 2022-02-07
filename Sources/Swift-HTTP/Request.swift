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

// Represents 1. request line (method, path) 2. Headers and 3. Body
public struct HTTPRequest {
    private var urlComponents = URLComponents() // does heavy lifting of fully-formed URL handling
    public var method: HTTPMethod = .get
    public var headers: [String: String] = [:]
    public var body: HTTPBody = EmptyBody() // defaults to EmptyBody()
    
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
