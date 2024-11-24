//
//  keychainFetch.swift
//  Umzug
//
//  Created by Jakob Danckwerts on 04.04.24.
//

import Foundation
import Security

enum KeychainError: Error {
    case unexpectedData
    case other(OSStatus)
}

func keychainFetch(_ server: String) throws -> (username: String?, password: String?)? {
    let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                kSecAttrServer as String: server,
                                kSecMatchLimit as String: kSecMatchLimitOne,
                                kSecReturnAttributes as String: true,
                                kSecReturnData as String: true]

    var result: AnyObject?
    switch SecItemCopyMatching(query as CFDictionary, &result) {
    case errSecSuccess: break
    case errSecItemNotFound: return nil
    case let status: throw KeychainError.other(status)
    }
    
    guard let dictionary = result as? [String : Any] else { throw KeychainError.unexpectedData }
    
    let username = dictionary[kSecAttrAccount as String] as? String
    let password = (dictionary[kSecValueData as String] as? Data).flatMap { String.init(data: $0, encoding: .utf8) }
    
    return (username: username, password: password)
}
