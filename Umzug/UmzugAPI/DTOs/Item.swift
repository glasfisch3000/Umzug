//
//  Item.swift
//  Umzug
//
//  Created by Jakob Danckwerts on 26.11.24.
//

import Foundation

struct Item: Sendable, Codable, Identifiable, Hashable {
    enum Priority: String, Sendable, Codable, Hashable {
        case immediate = "immediate"
        case standard = "standard"
        case longTerm = "long_term"
    }
    
    var id: UUID
    var title: String
    var priority: Priority
    var packings: [Packing]?
}

extension UmzugAPI.Request {
    static var items: Self { Self.init(method: .GET, path: ["items"], query: [:]) }
}

enum ItemsListFailure: UmzugAPIFailure {
    case invalidContent
    case noContent
    case serverError
}
