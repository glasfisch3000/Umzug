//
//  Packing.swift
//  Umzug
//
//  Created by Jakob Danckwerts on 26.11.24.
//

import Foundation

struct Packing: Sendable, Codable, Identifiable {
    var id: UUID
    var item: Item
    var box: Box
    var amount: Int
}
