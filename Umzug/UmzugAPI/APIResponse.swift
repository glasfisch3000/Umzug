//
//  APIResponse.swift
//  Umzug
//
//  Created by Jakob Danckwerts on 24.11.24.
//

import NIOCore
import NIOHTTP1

extension UmzugAPI {
    struct Response: Sendable {
        var statusCode: HTTPResponseStatus
        var body: ByteBuffer?
    }
}
