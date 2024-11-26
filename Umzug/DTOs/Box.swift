//
//  Box.swift
//  Umzug
//
//  Created by Jakob Danckwerts on 26.11.24.
//

import Foundation

struct Box: Sendable, Codable, Identifiable {
    var id: UUID
    var title: String
    var packings: [Packing]?
}
