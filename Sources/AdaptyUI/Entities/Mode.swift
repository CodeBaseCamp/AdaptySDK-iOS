//
//  Mode.swift
//  AdaptyUI
//
//  Created by Aleksei Valiano on 30.08.2024
//
//

import Foundation

package extension AdaptyUI {
    enum Mode<T>: Sendable, Hashable where T: Sendable, T: Hashable {
        case same(T)
        case different(light: T, dark: T)

        package enum Name: Int {
            case light
            case dark
        }
        
        package func mode(_ name: Name) -> T {
            switch self {
            case let .same(value):
                value
            case let .different(value1, value2):
                name == .light ? value1 : value2
            }
        }
    }
}

#if DEBUG
    package extension AdaptyUI.Mode {
        static func create(_ value: T) -> Self {
            .same(value)
        }

        static func create(light: T, dark: T) -> Self {
            .different(light: light, dark: dark)
        }
    }
#endif
