//
//  AdaptyPluginDecodingError.swift
//  AdaptyPlugin
//
//  Created by Aleksei Valiano on 07.11.2024.
//

enum AdaptyPluginDecodingError: Error {
    case unknownMethod(String)
    case notExist(key: String)
    case isNil(key: String)
    case wrongType(key: String?, expected: Any.Type, present: Any.Type)

    var localizedDescription: String {
        switch self {
        case .unknownMethod(let method):
            "Unknown request method: \(method)"
        case .notExist(key: let key):
            "Key \(key) not exist"
        case .isNil(key: let key):
            "Value by key(\(key)) is nil"
        case .wrongType(key: let key, expected: let expected, present: let present):
            if let key {
                "Value by key (\(key)) has wrong type. Expected \(expected), present \(present)"
            } else {
                "Value has wrong type. Expected \(expected), present \(present)"
            }
        }
    }
}
