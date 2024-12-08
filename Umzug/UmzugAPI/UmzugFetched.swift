import Foundation
import SwiftUI
import APIInterface

typealias UmzugFetched<Value> = Fetched<UmzugAPI, Value> where Value: Sendable

extension Fetched where API == UmzugAPI {
    init<Success: Sendable & Decodable, Failure: UmzugAPIFailure>(api: API, request: API.Request) where Result<Success, Failure> == Value {
        self.init(api: api, request: request) { @Sendable api, request throws(API.APIError) in
            try await api.makeRequest(request)
        }
    }
}
