//
//  APIRequest.swift
//  Umzug
//
//  Created by Jakob Danckwerts on 24.11.24.
//

import NIOHTTP1

extension UmzugAPI {
    struct Request: Sendable {
        var method: HTTPMethod
        var path: [String]
        var query: [String: String]
    }
}
