//
//  APIError.swift
//  Umzug
//
//  Created by Jakob Danckwerts on 24.11.24.
//

extension UmzugAPI {
    enum APIError: Sendable, Error {
        case invalidURL
        case invalidHeader
        case invalidAuthentication
        case clientShutdown
        case other
    }
}
