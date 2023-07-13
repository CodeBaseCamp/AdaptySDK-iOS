//
//  ViewConfiguration+extractLocale.swift
//  AdaptySDK
//
//  Created by Aleksei Valiano on 20.01.2023
//  Copyright © 2023 Adapty. All rights reserved.
//

import Foundation

extension AdaptyUI.ViewConfiguration {
    public func extractLocale(_ locale: String) -> AdaptyUI.LocalizedViewConfiguration {
        let localization: AdaptyUI.Localization?
        if let value = localizations[locale] {
            if defaultLocalization?.id == value.id {
                localization = value
            } else {
                localization = value.addDefault(localization: defaultLocalization)
            }
        } else {
            localization = defaultLocalization
        }

        func getAsset(_ id: String?) -> AdaptyUI.Asset? {
            guard let id = id else { return nil }
            return localization?.assets?[id] ?? assets[id]
        }
        func getAssetFont(_ id: String?) -> AdaptyUI.Font? {
            guard let asset = getAsset(id) else { return nil }
            switch asset {
            case let .font(value):
                return value
            default:
                return nil
            }
        }

        func getAssetFilling(_ id: String?) -> AdaptyUI.Filling? {
            guard let asset = getAsset(id) else { return nil }
            switch asset {
            case let .filling(value):
                return value
            default:
                return nil
            }
        }

        func getString(_ id: String?) -> String? {
            guard let id = id else { return nil }
            return localization?.strings?[id]
        }
        func getShapeOrNil(from value: AdaptyUI.ViewItem.Shape?) -> AdaptyUI.Shape? {
            guard let value else { return nil }
            return getShape(from: value)
        }
        func getShape(from item: AdaptyUI.ViewItem.Shape) -> AdaptyUI.Shape {
            var border: AdaptyUI.Shape.Border?
            if let filling = getAssetFilling(item.borderAssetId) {
                border = .init(filling: filling, thickness: item.borderThickness ?? AdaptyUI.Shape.Border.defaultThickness)
            }
            return AdaptyUI.Shape(
                background: getAssetFilling(item.backgroundAssetId),
                border: border,
                type: item.type
            )
        }

        func getButtonActionOrNil(from value: AdaptyUI.ButtonAction?) -> AdaptyUI.ButtonAction? {
            guard let value else { return nil }
            return getButtonAction(from: value)
        }

        func getButtonAction(from value: AdaptyUI.ButtonAction) -> AdaptyUI.ButtonAction {
            guard case let .openUrl(id) = value else { return value }
            return .openUrl(getString(id))
        }

        func getTextOrNil(from value: AdaptyUI.ViewItem.Text?) -> AdaptyUI.TextItems? {
            guard let value else { return nil }
            return getText(from: value)
        }

        func getText(from group: AdaptyUI.ViewItem.Text) -> AdaptyUI.TextItems {
            let defaultFont = getAssetFont(group.fontAssetId)
            let defaultFilling = getAssetFilling(group.fillAssetId)
            let defaultBullet = getAssetFilling(group.bulletAssetId)?.asImage

            return AdaptyUI.TextItems(
                items: group.items.map({ item in
                    let font = getAssetFont(item.fontAssetId) ?? defaultFont
                    return AdaptyUI.Text(
                        bullet: getAssetFilling(item.bulletAssetId)?.asImage ?? defaultBullet,
                        value: getString(item.stringId),
                        font: font,
                        size: item.size ?? group.size ?? font?.defaultSize,
                        fill: getAssetFilling(item.fillAssetId) ?? defaultFilling ?? font?.defaultFilling,
                        horizontalAlign: item.horizontalAlign ?? group.horizontalAlign ?? font?.defaultHorizontalAlign ?? AdaptyUI.Text.defaultHorizontalAlign
                    )
                }),
                separator: group.separator
            )
        }

        func convert(_ items: [String: AdaptyUI.ViewItem]?) -> [String: AdaptyUI.LocalizedViewItem] {
            items?.mapValues(convert) ?? [:]
        }

        func convert(_ item: [(key: String, value: AdaptyUI.ViewItem)]?) -> [(key: String, value: AdaptyUI.LocalizedViewItem)] {
            item?.map { (key: $0.key, value: convert($0.value)) } ?? []
        }

        func convert(_ item: AdaptyUI.ViewItem) -> AdaptyUI.LocalizedViewItem {
            switch item {
            case let .unknown(value):
                return .unknown(value)
            case let .asset(id):
                guard let asset = getAsset(id) else {
                    return .unknown("asset.id: \(id)")
                }
                switch asset {
                case let .filling(value):
                    return .filling(value)
                case let .unknown(value):
                    return .unknown(value)
                case .font:
                    return .unknown("unsupported asset {type: font, id: \(id)}")
                }
            case let .shape(value):
                return .shape(getShape(from: value))
            case let .button(value):
                let normal = AdaptyUI.Button.State(
                    shape: getShapeOrNil(from: value.shape),
                    title: getTextOrNil(from: value.title)
                )

                let selected = AdaptyUI.Button.State(
                    shape: getShapeOrNil(from: value.selectedShape),
                    title: getTextOrNil(from: value.selectedTitle)
                )

                return .button(AdaptyUI.Button(
                    normal: normal.isEmpty ? nil : normal,
                    selected: selected.isEmpty ? nil : selected,
                    align: value.align ?? AdaptyUI.Button.defaultAlign,
                    action: getButtonActionOrNil(from: value.action)
                ))
            case let .text(group):
                return .text(getText(from: group))
            }
        }

        var styles = [String: AdaptyUI.LocalizedViewStyle]()
        styles.reserveCapacity(self.styles.count)

        for style in self.styles {
            styles[style.key] = AdaptyUI.LocalizedViewStyle(
                featureBlock: style.value.featuresBlock.map { AdaptyUI.FeaturesBlock(
                    type: $0.type,
                    items: convert($0.items)
                ) },
                productBlock: AdaptyUI.ProductsBlock(
                    type: style.value.productsBlock.type,
                    mainProductIndex: style.value.productsBlock.mainProductIndex,
                    items: convert(style.value.productsBlock.items)
                ),
                footerBlock: style.value.footerBlock.map { AdaptyUI.FooterBlock(
                    orderedItems: convert($0.orderedItems)
                ) },
                items: convert(style.value.items))
        }

        return AdaptyUI.LocalizedViewConfiguration(
            id: id,
            templateId: templateId,
            locale: localization?.id ?? locale,
            styles: styles,
            isHard: isHard,
            mainImageRelativeHeight: mainImageRelativeHeight,
            version: version
        )
    }
}

extension AdaptyUI.Localization {
    fileprivate func addDefault(localization: Self?) -> Self {
        guard let localization = localization else { return self }

        var strings = self.strings ?? [:]
        if let other = localization.strings {
            strings = strings.merging(other, uniquingKeysWith: { current, _ in current })
        }

        var assets = self.assets ?? [:]
        if let other = localization.assets {
            assets = assets.merging(other, uniquingKeysWith: { current, _ in current })
        }

        return AdaptyUI.Localization(
            id: id,
            strings: strings.isEmpty ? nil : strings,
            assets: assets.isEmpty ? nil : assets
        )
    }
}
