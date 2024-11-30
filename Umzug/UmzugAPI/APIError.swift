//
//  APIError.swift
//  Umzug
//
//  Created by Jakob Danckwerts on 24.11.24.
//

import NIOHTTP1
import APIInterface

extension UmzugAPI {
    enum APIError: APIErrorProtocol, Hashable, Decodable {
        case invalidURL
        case invalidAuthentication
        case clientShutdown
        case invalidStatus(HTTPResponseStatus)
        case other
        
        enum CodingKeys: CodingKey {
            case invalidAuthentication
        }
        
        var shouldReport: Bool {
            switch self {
            case .invalidURL, .invalidStatus(_): false
            case .invalidAuthentication, .clientShutdown, .other: true
            }
        }
    }
}
