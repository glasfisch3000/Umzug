//
//  UmzugAPI.swift
//  Umzug
//
//  Created by Jakob Danckwerts on 24.11.24.
//

import SwiftUI
import APIInterface
import NIOCore
import AsyncHTTPClient

struct UmzugAPI: DynamicProperty, APIProtocol {
    typealias Response = ByteBuffer?
    
    var client: HTTPClient
    var server: APIServer
    var authentication: Authentication
    
    init(client: HTTPClient = .shared, server: APIServer, authentication: Authentication) {
        self.client = client
        self.server = server
        self.authentication = authentication
    }
    
    func makeRequest(_ request: Request) async throws(APIError) -> Response {
        let path = request.path.joined(separator: "/")
        let query = request.query.compactMap {
            guard let key = $0.key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let value = $0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                return nil
            }
            return "\(key)=\(value)"
        }.joined(separator: "&")
        
        let url = "\(self.server.scheme)://\(self.server.host):\(self.server.port)/api/\(path)?\(query)"
        
        do {
            let result = try await self.client.get(url: url, deadline: .now() + .seconds(10)).get()
            
            guard result.status == .ok else {
                throw APIError.invalidStatus(result.status)
            }
            
            struct APIErrorResponse: Decodable {
                var error: APIError
            }
            
            if let body = result.body, let error = try? JSONDecoder().decode(APIErrorResponse.self, from: body) {
                throw error.error
            }
            
            return result.body
        } catch let error as APIError {
            print(error)
            throw error
        } catch let error as HTTPClientError {
            print(error)
            switch error {
            case .invalidURL, .emptyScheme, .emptyHost: throw APIError.invalidURL
            case .alreadyShutdown: throw APIError.clientShutdown
            default: throw APIError.other
            }
        } catch {
            print(error)
            throw APIError.other
        }
    }
    
    func reportError(_ apiError: APIError) {
        
    }
}
