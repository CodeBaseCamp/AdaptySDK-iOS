//
//  Button.swift
//  AdaptySDK
//
//  Created by Aleksei Valiano on 28.03.2024
//
//

import Foundation

extension AdaptyUI.ViewConfiguration {
    struct Button {
        let action: AdaptyUI.ButtonAction?
        let isSelected: Bool
        let normalState: AdaptyUI.ViewConfiguration.Element?
        let selectedState: AdaptyUI.ViewConfiguration.Element?
    }
}

extension AdaptyUI.ViewConfiguration.Localizer {
    func button(from: AdaptyUI.ViewConfiguration.Button) -> AdaptyUI.Button {
        .init(
            action: from.action.map(buttonAction),
            isSelected: from.isSelected,
            normalState: from.normalState.map(element),
            selectedState: from.selectedState.map(element)
        )
    }

    func buttonAction(from: AdaptyUI.ButtonAction) -> AdaptyUI.ButtonAction {
        guard case let .openUrl(stringId) = from else { return from }
        return .openUrl(self.urlIfPresent(stringId))
    }
}
