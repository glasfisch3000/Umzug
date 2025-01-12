//
//  Packing.swift
//  Umzug
//
//  Created by Jakob Danckwerts on 26.11.24.
//

import Foundation

struct Packing: Sendable, Codable, Identifiable, Hashable {
    var id: UUID
    var item: Item
    var box: Box
    var amount: Int
    
    struct DTO: Sendable, Codable, Identifiable, Hashable {
        var id: UUID
        var item: Item?
        var box: Box?
        var amount: Int
    }
    
    func delete(on api: UmzugAPI) async throws(UmzugAPI.APIError) -> Result<Packing.DTO, PackingsDeleteFailure> {
        try await api.makeRequest(.deletePacking(id: self.id), success: Packing.DTO.self, failure: PackingsDeleteFailure.self)
    }
}

extension UmzugAPI.Request {
    static func packings(item: UUID? = nil, box: UUID? = nil) -> Self {
        var query: [String: String] = [:]
        
        if let item = item { query["itemID"] = item.uuidString }
        if let box = box { query["boxID"] = box.uuidString }
        
        return Self.init(method: .GET, path: ["packings"], query: query)
    }
    
    static func createPacking(item: UUID, box: UUID, amount: Int) -> Self {
        Self.init(method: .POST, path: ["packings"], query: ["itemID": item.uuidString, "boxID": box.uuidString, "amount": amount.description])
    }
    
    static func updatePacking(_ id: UUID, item: UUID? = nil, box: UUID? = nil, amount: Int? = nil) -> Self {
        var query: [String: String] = [:]
        
        if let item = item { query["itemID"] = item.uuidString }
        if let box = box { query["boxID"] = box.uuidString }
        if let amount = amount { query["amount"] = amount.description }
        
        return Self.init(method: .PATCH, path: ["packings", id.uuidString], query: query)
    }
    
    static func deletePacking(id: UUID) -> Self {
        Self.init(method: .DELETE, path: ["packings", id.uuidString], query: [:])
    }
}


enum PackingConstraintViolation: Decodable {
    case packing_unique(item: UUID, box: UUID)
    case packing_nonzero(amount: Int)
}

enum PackingsListFailure: UmzugAPIFailure {
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

enum PackingsCreateFailure: UmzugAPIFailure {
    enum ConstraintViolationCodingKeys: String, CodingKey {
        case _0 = "constraint"
    }
    
    case invalidContent
    case noContent
    case constraintViolation(PackingConstraintViolation)
    
    var description: String {
        switch self {
        case .invalidContent, .noContent: "Received an invalid or empty API response."
        case .constraintViolation(.packing_unique(item: _, box: _)): "This item is already packed into this box."
        case .constraintViolation(.packing_nonzero(amount: _)): "This packing has an invalid amount."
        }
    }
}

enum PackingsUpdateFailure: UmzugAPIFailure {
    enum ConstraintViolationCodingKeys: String, CodingKey {
        case _0 = "constraint"
    }
    
    enum ModelNotFoundCodingKeys: String, CodingKey {
        case _0 = "modelID"
    }
    
    case invalidContent
    case noContent
    case constraintViolation(PackingConstraintViolation)
    case modelNotFound(UUID)
    
    var description: String {
        switch self {
        case .invalidContent, .noContent: "Received an invalid or empty API response."
        case .constraintViolation(.packing_unique(item: _, box: _)): "This item is already packed into this box."
        case .constraintViolation(.packing_nonzero(amount: _)): "This packing has an invalid amount."
        case .modelNotFound(let id): "Packing not found for ID \(id)."
        }
    }
}

enum PackingsDeleteFailure: UmzugAPIFailure {
    enum ModelNotFoundCodingKeys: String, CodingKey {
        case _0 = "modelID"
    }
    
    case invalidContent
    case noContent
    case modelNotFound(UUID)
    
    var description: String {
        switch self {
        case .invalidContent, .noContent: "Received an invalid or empty API response."
        case .modelNotFound(let id): "Packing not found for ID \(id)."
        }
    }
}
