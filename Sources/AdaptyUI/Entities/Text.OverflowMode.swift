//
//  Text.OverflowMode.swift
//  AdaptyUI
//
//  Created by Aleksei Valiano on 01.05.2024
//
//

import Foundation

extension AdaptyUI.Text {
    package enum OverflowMode: String {
        case scale
        case unknown
    }
}

extension AdaptyUI.Text.OverflowMode: Decodable {
    package init(from decoder: Decoder) throws {
        self =
            switch try decoder.singleValueContainer().decode(String.self) {
            case "scale":
                .scale
            default:
                .unknown
            }
    }
}
