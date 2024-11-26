//
//  Item.swift
//  Umzug
//
//  Created by Jakob Danckwerts on 26.11.24.
//

import Foundation

struct Item: Sendable, Codable, Identifiable {
    enum Priority: String, Sendable, Codable {
        case immediate = "immediate"
        case standard = "standard"
        case convenience = "convenience"
        case longTerm = "long_term"
    }
    
    var id: UUID
    var title: String
    var priority: Priority?
    var packings: [Packing]?
}
