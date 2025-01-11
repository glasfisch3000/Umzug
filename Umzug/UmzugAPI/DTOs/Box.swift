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


enum BoxConstraintViolation: Decodable {
    case box_unique(title: String)
}

enum BoxesListFailure: UmzugAPIFailure {
    case invalidContent
    case noContent
    case serverError
}

enum BoxesCreateFailure: UmzugAPIFailure {
    enum ConstraintViolationCodingKeys: String, CodingKey {
        case _0 = "constraint"
    }
    
    case invalidContent
    case noContent
    case constraintViolation(BoxConstraintViolation)
}

enum BoxesDeleteFailure: UmzugAPIFailure {
    enum ModelNotFoundCodingKeys: String, CodingKey {
        case _0 = "modelID"
    }
    
    case invalidContent
    case noContent
    case modelNotFound(UUID)
}
