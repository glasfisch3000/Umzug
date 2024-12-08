//
//  UmzugAPIFailure.swift
//  Umzug
//
//  Created by Jakob Danckwerts on 04.12.24.
//

protocol UmzugAPIOptionalFailure: Error, Decodable {
    static var invalidContent: Self { get }
}

protocol UmzugAPIFailure: Error, Decodable {
    static var invalidContent: Self { get }
    static var noContent: Self { get }
}
