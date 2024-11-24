//
//  APIServer.swift
//  Umzug
//
//  Created by Jakob Danckwerts on 24.11.24.
//

extension UmzugAPI {
    struct APIServer {
        enum HTTPScheme: String {
            case http, https
        }
        
        var scheme: HTTPScheme
        var host: String
        var port: UInt16
    }
}
