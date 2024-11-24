//
//  keychainAdd.swift
//  Umzug
//
//  Created by Jakob Danckwerts on 05.04.24.
//

import Foundation
import Security

func keychainAdd(_ server: String, username: String, password: String) throws {
    let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                kSecAttrAccount as String: username,
                                kSecAttrServer as String: server,
                                kSecValueData as String: Data(password.utf8)]
    
    let status = SecItemAdd(query as CFDictionary, nil)
    guard status == errSecSuccess else { throw KeychainError.other(status) }
}
