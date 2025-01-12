//
//  Item.swift
//  Umzug
//
//  Created by Jakob Danckwerts on 26.11.24.
//

import Foundation

struct Item: Sendable, Codable, Identifiable, Hashable {
    enum Priority: String, Sendable, Codable, Hashable, CaseIterable, Identifiable {
        case immediate = "immediate"
        case standard = "standard"
        case longTerm = "long_term"
        
        var id: Self { self }
    }
    
    var id: UUID
    var title: String
    var priority: Priority
    var packings: [Packing]?
    
    func delete(on api: UmzugAPI) async throws(UmzugAPI.APIError) -> Result<Item, ItemsDeleteFailure> {
        try await api.makeRequest(.deleteItem(id: self.id), success: Item.self, failure: ItemsDeleteFailure.self)
    }
}

extension UmzugAPI.Request {
    static var items: Self { Self.init(method: .GET, path: ["items"], query: [:]) }
    
    static func createItem(title: String, priority: Item.Priority) -> Self {
        return Self.init(method: .POST, path: ["items"], query: ["title": title, "priority": priority.rawValue])
    }
    
    static func updateItem(_ id: UUID, title: String?, priority: Item.Priority? = nil) -> Self {
        var query: [String: String] = [:]
        
        if let title = title { query["title"] = title }
        if let priority = priority { query["priority"] = priority.rawValue }
        
        return Self.init(method: .PATCH, path: ["items", id.uuidString], query: query)
    }
    
    static func deleteItem(id: UUID) -> Self {
        Self.init(method: .DELETE, path: ["items", id.uuidString], query: [:])
    }
}


enum ItemConstraintViolation: Decodable {
    case item_unique(title: String)
}

enum ItemsListFailure: UmzugAPIFailure {
    case invalidContent
    case noContent
    case serverError
    
    var description: String {
        switch self {
        case .invalidContent, .noContent: "Received an invalid or empty API response."
        case .serverError: "An internal API error occurred."
        }
    }
}

enum ItemsCreateFailure: UmzugAPIFailure {
    enum ConstraintViolationCodingKeys: String, CodingKey {
        case _0 = "constraint"
    }
    
    case invalidContent
    case noContent
    case constraintViolation(ItemConstraintViolation)
    
    var description: String {
        switch self {
        case .invalidContent, .noContent: "Received an invalid or empty API response."
        case .constraintViolation(.item_unique(title: _)): "An item with this title already exists."
        }
    }
}

enum ItemsUpdateFailure: UmzugAPIFailure {
    enum ConstraintViolationCodingKeys: String, CodingKey {
        case _0 = "constraint"
    }
    
    enum ModelNotFoundCodingKeys: String, CodingKey {
        case _0 = "modelID"
    }
    
    case invalidContent
    case noContent
    case constraintViolation(ItemConstraintViolation)
    case modelNotFound(UUID)
    
    var description: String {
        switch self {
        case .invalidContent, .noContent: "Received an invalid or empty API response."
        case .constraintViolation(.item_unique(title: _)): "An item with this title already exists."
        case .modelNotFound(let id): "Item not found for ID \(id)."
        }
    }
}

enum ItemsDeleteFailure: UmzugAPIFailure {
    enum ModelNotFoundCodingKeys: String, CodingKey {
        case _0 = "modelID"
    }
    
    case invalidContent
    case noContent
    case modelNotFound(UUID)
    
    var description: String {
        switch self {
        case .invalidContent, .noContent: "Received an invalid or empty API response."
        case .modelNotFound(let id): "Item not found for ID \(id)."
        }
    }
}
