//
//  ViewConfiguration.Localizer.swift
//  AdaptyUI
//
//  Created by Aleksei Valiano on 20.01.2023
//

import Foundation

extension AdaptyUI.ViewConfiguration {
    struct Localizer {
        let localization: Localization?
        let source: AdaptyUI.ViewConfiguration
        let locale: AdaptyLocale

        init(source: AdaptyUI.ViewConfiguration, withLocale: AdaptyLocale) {
            self.source = source
            self.localization = source.getLocalization(withLocale)
            self.locale = self.localization?.id ?? withLocale
        }
    }
}

extension AdaptyUI.ViewConfiguration.Localizer {
    func localize() -> AdaptyUI.LocalizedViewConfiguration {
        .init(
            id: source.id,
            locale: locale.id,
            isRightToLeft: localization?.isRightToLeft ?? false,
            templateId: source.templateId,
            screen: screen(source.defaultScreen),
            bottomSheets: source.screens.mapValues(bottomSheet),
            templateRevision: source.templateRevision
        )
    }
}
