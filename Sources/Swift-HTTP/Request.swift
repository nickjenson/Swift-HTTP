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

public protocol HTTPLoading {
    func load(request: HTTPRequest, completion: @escaping (HTTPResult) -> Void)
}

extension URLSession: HTTPLoading {
    public func load(request: HTTPRequest, completion: @escaping (HTTPResult) -> Void) {
        guard let url = request.url else {
            // can't construct proper URL out of request's URLComponents
            completion(.failure(HTTPError(code: .invalidRequest, request: request, response: nil, underlyingError: nil)))
            return
        }
        // construct request
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        
        // copy over any custom HTTP headers
        for(header, value) in request.headers {
            urlRequest.addValue(value, forHTTPHeaderField: header)
        }
        
        if request.body.isEmpty == false {
            // if body defines headers, add them
            for(header, value) in request.body.additionalHeaders {
                urlRequest.addValue(value, forHTTPHeaderField: header)
            }
            // attempt to retrieve the body data
            do {
                urlRequest.httpBody = try request.body.encode()
            } catch {
                // error creating body; stop and report back
                completion(.failure(HTTPError(code: .invalidRequest, request: request, response: nil, underlyingError: nil)))
                return
            }
        }
        
        let dataTask = session.dataTask(with: urlRequest) { (data, response, error) in
            let result = HTTPResult(request: request, reponseData: data, reponse: response, error: error)
            completion(result)
        }
        
        dataTask.resume()
    }
}
