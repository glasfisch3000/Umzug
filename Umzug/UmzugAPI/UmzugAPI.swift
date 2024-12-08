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
import Synchronization

@Observable
final class UmzugAPI: @unchecked Sendable {
    enum APIStatus: Sendable {
        case normal
        case error(APIError)
    }
    
    let client: HTTPClient
    let server: APIServer
    let authentication: Authentication
    
    init(client: HTTPClient = .shared, server: APIServer, authentication: Authentication) {
        self.client = client
        self.server = server
        self.authentication = authentication
    }
    
    var apiError: APIError? = nil
    private let apiErrorSemaphore = DispatchSemaphore(value: 1)
    
    var status: APIStatus {
        switch self.apiError {
        case .some(let error): .error(error)
        case nil: .normal
        }
    }
}

extension UmzugAPI: APIProtocol {
    typealias Response = ByteBuffer?
    
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
        let authContent = Data((self.authentication.username + ":" + self.authentication.password).utf8)
        let authEncoded = "Basic " + authContent.base64EncodedString()
            
        do {
            var request = try HTTPClient.Request(url: url, method: request.method)
            request.headers.add(name: "Authorization", value: authEncoded)
            
            let result = try await self.client.execute(request: request, deadline: .now() + .seconds(10)).get()
            
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
        } catch let error as HTTPClientError {
            print(error)
            switch error {
            case .invalidURL, .emptyScheme, .emptyHost: throw APIError.invalidURL
            case .alreadyShutdown: throw APIError.clientShutdown
            default: throw APIError.other
            }
        } catch let error as APIError {
            print(error)
            throw error
        } catch let error {
            print(error)
            throw APIError.other
        }
    }
    
    func reportError(_ apiError: APIError) {
        self.apiErrorSemaphore.wait()
        self.apiError = self.apiError ?? apiError
        self.apiErrorSemaphore.signal()
    }
}

extension UmzugAPI {
    private struct _APIResponseData<F: Decodable>: Decodable {
        var error: F
    }
    
    public func makeRequest<Success: Sendable & Decodable, Failure: UmzugAPIFailure>(
        _ request: Request,
        success: Success.Type = Success.self,
        failure: Failure.Type = Failure.self
    ) async throws(APIError) -> Result<Success, Failure> {
        let response = try await self.makeRequest(request)
        do throws(Failure) {
            guard let body = response else {
                throw .noContent
            }
            
            print(try? body.getString(at: body.readerIndex, length: body.readableBytes))
            
            if let error = try? JSONDecoder().decode(_APIResponseData<Failure>.self, from: body).error {
                throw error
            }
            
            if let content = try? JSONDecoder().decode(Success.self, from: body) {
                return .success(content)
            } else {
                throw .invalidContent
            }
        } catch {
            print(error)
            return .failure(error)
        }
    }
}
