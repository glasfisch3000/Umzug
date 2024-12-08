//
//  Box.swift
//  Umzug
//
//  Created by Jakob Danckwerts on 26.11.24.
//

import Foundation

struct Box: Sendable, Codable, Identifiable, Hashable {
    var id: UUID
    var title: String
    var packings: [Packing]?
}

extension UmzugAPI.Request {
    static var boxes: Self { Self.init(method: .GET, path: ["boxes"], query: [:]) }
    
    static func createBox(title: String) -> Self {
        Self.init(method: .POST, path: ["boxes"], query: ["title": title])
    }
}

enum BoxesListFailure: UmzugAPIFailure {
    case invalidContent
    case noContent
    case serverError
}

enum BoxesCreateFailure: UmzugAPIFailure {
    enum UniqueConstraintViolationCodingKeys: String, CodingKey {
        case _0 = "constraint"
    }
    
    enum UniqueConstraintViolation: Decodable {
        case boxes(title: String)
    }
    
    case invalidContent
    case noContent
    case uniqueConstraintViolation(UniqueConstraintViolation)
}
