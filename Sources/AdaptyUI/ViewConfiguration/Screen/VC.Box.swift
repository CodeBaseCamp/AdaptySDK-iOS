//
//  VC.Box.swift
//  AdaptyUI
//
//  Created by Aleksei Valiano on 28.03.2024
//
//

import Foundation

extension AdaptyUI.ViewConfiguration {
    struct Box {
        let width: AdaptyUI.Box.Length?
        let height: AdaptyUI.Box.Length?
        let horizontalAlignment: AdaptyUI.HorizontalAlignment
        let verticalAlignment: AdaptyUI.VerticalAlignment
        let content: AdaptyUI.ViewConfiguration.Element
    }
}

extension AdaptyUI.ViewConfiguration.Localizer {
    func box(_ from: AdaptyUI.ViewConfiguration.Box) -> AdaptyUI.Box {
        .init(
            width: from.width,
            height: from.height,
            horizontalAlignment: from.horizontalAlignment,
            verticalAlignment: from.verticalAlignment,
            content: element(from.content)
        )
    }
}

extension AdaptyUI.ViewConfiguration.Box: Decodable {
    enum CodingKeys: String, CodingKey {
        case width
        case height
        case horizontalAlignment = "h_align"
        case verticalAlignment = "v_align"
        case content
    }

    init(from decoder: any Decoder) throws {
        let def = AdaptyUI.Stack.default
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            width: try? container.decodeIfPresent(AdaptyUI.Box.Length.self, forKey: .width),
            height: try? container.decodeIfPresent(AdaptyUI.Box.Length.self, forKey: .height),
            horizontalAlignment: container.decodeIfPresent(AdaptyUI.HorizontalAlignment.self, forKey: .horizontalAlignment) ?? def.horizontalAlignment,
            verticalAlignment: container.decodeIfPresent(AdaptyUI.VerticalAlignment.self, forKey: .verticalAlignment) ?? def.verticalAlignment,
            content: container.decode(AdaptyUI.ViewConfiguration.Element.self, forKey: .content)
        )
    }
}

extension AdaptyUI.Box.Length: Decodable {
    enum CodingKeys: String, CodingKey {
        case min
        case fillMax = "fill_max"
    }

    package init(from decoder: any Decoder) throws {
        if let value = try? decoder.singleValueContainer().decode(AdaptyUI.Unit.self) {
            self = .fixed(value)
        } else {
            let conteineer = try decoder.container(keyedBy: CodingKeys.self)
            if let value = try conteineer.decodeIfPresent(Bool.self, forKey: .fillMax), value {
                self = .fillMax
            } else if let value = try conteineer.decodeIfPresent(AdaptyUI.Unit.self, forKey: .min) {
                self = .min(value)
            } else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: conteineer.codingPath, debugDescription: "don't found fill_max:true or min"))
            }
        }
    }
}
