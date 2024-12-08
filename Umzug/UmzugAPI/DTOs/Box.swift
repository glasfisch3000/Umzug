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
    static var boxes: Self { Self.init(path: ["boxes"], query: [:]) }
}
