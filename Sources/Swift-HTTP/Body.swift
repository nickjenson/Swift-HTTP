//
//  Body.swift
//  
//
//  Created by Nick Jenson on 2/6/22.
//

import Foundation

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
