//
//  VC.Decorator.swift
//  AdaptyUI
//
//  Created by Aleksei Valiano on 28.03.2024
//
//

import Foundation

extension AdaptyUI.ViewConfiguration {
    struct Decorator {
        let shapeType: AdaptyUI.ShapeType
        let backgroundAssetId: String?
        let borderAssetId: String?
        let borderThickness: Double?
    }
}

extension AdaptyUI.ViewConfiguration.Localizer {
    func decorator(_ from: AdaptyUI.ViewConfiguration.Decorator) throws -> AdaptyUI.Decorator {
        .init(
            shapeType: from.shapeType,
            background: fillingIfPresent(from.backgroundAssetId),
            border: fillingIfPresent(from.borderAssetId).map {
                AdaptyUI.Border(filling: $0, thickness: from.borderThickness ?? AdaptyUI.Border.defaultThickness)
            }
        )
    }
}

extension AdaptyUI.ViewConfiguration.Decorator: Decodable {
    enum CodingKeys: String, CodingKey {
        case backgroundAssetId = "background"
        case rectangleCornerRadius = "rect_corner_radius"
        case borderAssetId = "border"
        case borderThickness = "thickness"
        case shapeType = "type"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        backgroundAssetId = try container.decodeIfPresent(String.self, forKey: .backgroundAssetId)
        let shape = (try? container.decode(AdaptyUI.ShapeType.self, forKey: .shapeType)) ?? AdaptyUI.Decorator.defaultShapeType

        if case .rectangle = shape,
           let rectangleCornerRadius = try container.decodeIfPresent(AdaptyUI.CornerRadius.self, forKey: .rectangleCornerRadius) {
            shapeType = .rectangle(cornerRadius: rectangleCornerRadius)
        } else {
            shapeType = shape
        }

        if let assetId = try container.decodeIfPresent(String.self, forKey: .borderAssetId) {
            borderAssetId = assetId
            borderThickness = try container.decodeIfPresent(Double.self, forKey: .borderThickness)
        } else {
            borderAssetId = nil
            borderThickness = nil
        }
    }
}
