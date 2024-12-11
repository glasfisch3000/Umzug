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
    
    @discardableResult
    func delete(on api: UmzugAPI) async throws(UmzugAPI.APIError) -> Result<Box, BoxesDeleteFailure> {
        try await api.makeRequest(.deleteBox(id: self.id), success: Box.self, failure: BoxesDeleteFailure.self)
    }
}

extension UmzugAPI.Request {
    static var boxes: Self { Self.init(method: .GET, path: ["boxes"], query: [:]) }
    
    static func createBox(title: String) -> Self {
        Self.init(method: .POST, path: ["boxes"], query: ["title": title])
    }
    
    static func deleteBox(id: UUID) -> Self {
        Self.init(method: .DELETE, path: ["boxes", id.uuidString], query: [:])
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

enum BoxesDeleteFailure: UmzugAPIFailure {
    enum ModelNotFoundCodingKeys: String, CodingKey {
        case _0 = "modelID"
    }
    
    case invalidContent
    case noContent
    case modelNotFound(UUID)
}
