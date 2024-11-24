//
//  APIRequest.swift
//  Umzug
//
//  Created by Jakob Danckwerts on 24.11.24.
//

extension UmzugAPI {
    struct Request {
        var path: [String]
        var query: [String: String]
    }
}
