//
//  APIError.swift
//  Umzug
//
//  Created by Jakob Danckwerts on 24.11.24.
//

import NIOHTTP1

extension UmzugAPI {
    enum APIError: Sendable, Error, Decodable {
        case invalidURL
        case invalidAuthentication
        case clientShutdown
        case invalidStatus(HTTPResponseStatus)
        case other
        
        enum CodingKeys: CodingKey {
            case invalidAuthentication
        }
    }
}
