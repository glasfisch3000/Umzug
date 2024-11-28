import Foundation
import NIOHTTP1
import APIInterface

typealias UmzugFetched<Value> = Fetched<UmzugAPI, Value>

protocol UmzugAPIOptionalFailure: Error, Decodable {
    static var invalidContent: Self { get }
}

protocol UmzugAPIFailure: UmzugAPIOptionalFailure {
    static var noContent: Self { get }
}

extension Fetched where API == UmzugAPI {
    fileprivate struct _APIResponseData<F: Decodable>: Decodable {
        var error: F?
    }
    
    init<Success: Decodable, Failure: UmzugAPIFailure>(api: API, request: API.Request)
    where Value == Result<Success, Failure> {
        self.init(api: api, request: request) { response in
            do throws(Failure) {
                guard let body = response else {
                    throw .noContent
                }
                
                print(body.getString(at: body.readerIndex, length: body.readableBytes, encoding: .utf8))
                
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
    
    init<Success: Decodable, Failure: UmzugAPIOptionalFailure>(api: API, request: API.Request)
    where Value == Result<Success?, Failure> {
        self.init(api: api, request: request) { response in
            do throws(Failure) {
                guard let body = response else {
                    return .success(nil)
                }
                
                print(body.getString(at: body.readerIndex, length: body.readableBytes, encoding: .utf8))
                
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
}
