//
//  OldShape.swift
//  AdaptySDK
//
//  Created by Aleksei Valiano on 30.06.2023
//

import Foundation

extension AdaptyUI {
    public struct OldShape {
        static let defaultType: ShapeType = .rectangle(cornerRadius: CornerRadius.zero)

        public let background: Filling?
        public let border: Border?
        public let type: ShapeType
    }
}
