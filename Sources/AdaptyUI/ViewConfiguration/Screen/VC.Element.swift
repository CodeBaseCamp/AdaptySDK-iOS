//
//  VC.Element.swift
//  AdaptyUI
//
//  Created by Aleksei Valiano on 28.03.2024
//
//

import Foundation

extension AdaptyUI.ViewConfiguration {
    enum Element {
        case space(Int)
        case reference(String)
        indirect case stack(AdaptyUI.ViewConfiguration.Stack, Properties?)
        case text(AdaptyUI.ViewConfiguration.Text, Properties?)
        case image(AdaptyUI.ViewConfiguration.Image, Properties?)
        indirect case button(AdaptyUI.ViewConfiguration.Button, Properties?)
        indirect case box(AdaptyUI.ViewConfiguration.Box, Properties?)
        indirect case row(AdaptyUI.ViewConfiguration.Row, Properties?)
        indirect case column(AdaptyUI.ViewConfiguration.Column, Properties?)
        indirect case section(AdaptyUI.ViewConfiguration.Section, Properties?)
        case toggle(AdaptyUI.ViewConfiguration.Toggle, Properties?)
        case timer(AdaptyUI.ViewConfiguration.Timer, Properties?)
        indirect case pager(AdaptyUI.ViewConfiguration.Pager, Properties?)

        case unknown(String, Properties?)
    }
}

extension AdaptyUI.ViewConfiguration.Element {
    struct Properties {
        let elementId: String?
        let decorator: AdaptyUI.ViewConfiguration.Decorator?
        let padding: AdaptyUI.EdgeInsets
        let offset: AdaptyUI.Offset

        let visibility: Bool
        let transitionIn: [AdaptyUI.Transition]

        var isZero: Bool {
            decorator == nil
                && padding.isZero
                && offset.isZero
                && visibility
                && transitionIn.isEmpty
        }
    }
}

extension AdaptyUI.ViewConfiguration.Localizer {
    func element(_ from: AdaptyUI.ViewConfiguration.Element) -> AdaptyUI.Element {
        switch from {
        case let .space(value):
            .space(value)
        case let .reference(id):
            .unknown("reference to `\(id)`", nil)
        case let .stack(value, properties):
            .stack(stack(value), properties.flatMap(elementProperties))
        case let .text(value, properties):
            .text(text(value), properties.flatMap(elementProperties))
        case let .image(value, properties):
            .image(image(value), properties.flatMap(elementProperties))
        case let .button(value, properties):
            .button(button(value), properties.flatMap(elementProperties))
        case let .box(value, properties):
            .box(box(value), properties.flatMap(elementProperties))
        case let .row(value, properties):
            .row(row(value), properties.flatMap(elementProperties))
        case let .column(value, properties):
            .column(column(value), properties.flatMap(elementProperties))
        case let .section(value, properties):
            .section(section(value), properties.flatMap(elementProperties))
        case let .toggle(value, properties):
            .toggle(toggle(value), properties.flatMap(elementProperties))
        case let .timer(value, properties):
            .timer(timer(value), properties.flatMap(elementProperties))
        case let .pager(value, properties):
            .pager(pager(value), properties.flatMap(elementProperties))

        case let .unknown(value, properties):
            .unknown(value, properties.flatMap(elementProperties))
        }
    }

    private func elementProperties(_ from: AdaptyUI.ViewConfiguration.Element.Properties) -> AdaptyUI.Element.Properties? {
        guard !from.isZero else { return nil }
        return .init(
            decorator: from.decorator.map(decorator),
            padding: from.padding,
            offset: from.offset,
            visibility: from.visibility,
            transitionIn: from.transitionIn
        )
    }
}

extension AdaptyUI.ViewConfiguration.Element: Decodable {
    enum CodingKeys: String, CodingKey {
        case type
        case count
        case id
    }

    enum ContentType: String, Codable {
        case text
        case image
        case button
        case box
        case space
        case vStack = "v_stack"
        case hStack = "h_stack"
        case zStack = "z_stack"
        case row
        case column
        case section
        case toggle
        case timer
        case `if`
        case reference
        case pager
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        guard let contentType = ContentType(rawValue: type) else {
            self = .unknown(type, propertyOrNil())
            return
        }

        switch contentType {
        case .if:
            self = try AdaptyUI.ViewConfiguration.If(from: decoder).content
        case .reference:
            self = try .reference(container.decode(String.self, forKey: .id))
        case .space:
            self = try .space(container.decodeIfPresent(Int.self, forKey: .count) ?? 1)
        case .box:
            self = try .box(AdaptyUI.ViewConfiguration.Box(from: decoder), propertyOrNil())
        case .vStack, .hStack, .zStack:
            self = try .stack(AdaptyUI.ViewConfiguration.Stack(from: decoder), propertyOrNil())
        case .button:
            self = try .button(AdaptyUI.ViewConfiguration.Button(from: decoder), propertyOrNil())
        case .text:
            self = try .text(AdaptyUI.ViewConfiguration.Text(from: decoder), propertyOrNil())
        case .image:
            self = try .image(AdaptyUI.ViewConfiguration.Image(from: decoder), propertyOrNil())
        case .row:
            self = try .row(AdaptyUI.ViewConfiguration.Row(from: decoder), propertyOrNil())
        case .column:
            self = try .column(AdaptyUI.ViewConfiguration.Column(from: decoder), propertyOrNil())
        case .section:
            self = try .section(AdaptyUI.ViewConfiguration.Section(from: decoder), propertyOrNil())
        case .toggle:
            self = try .toggle(AdaptyUI.ViewConfiguration.Toggle(from: decoder), propertyOrNil())
        case .timer:
            self = try .timer(AdaptyUI.ViewConfiguration.Timer(from: decoder), propertyOrNil())
        case .pager:
            self = try .pager(AdaptyUI.ViewConfiguration.Pager(from: decoder), propertyOrNil())
        }

        func propertyOrNil() -> Properties? {
            guard let value = try? Properties(from: decoder) else { return nil }
            return value.isZero ? nil : value
        }
    }
}

extension AdaptyUI.ViewConfiguration.Element.Properties: Decodable {
    enum CodingKeys: String, CodingKey {
        case elementId = "element_id"
        case decorator
        case padding
        case offset
        case visibility
        case transitionIn = "transition_in"
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let transitionIn: [AdaptyUI.Transition] =
            if let array = try? container.decodeIfPresent([AdaptyUI.Transition].self, forKey: .transitionIn) {
                array
            } else if let transition = try container.decodeIfPresent(AdaptyUI.Transition.self, forKey: .transitionIn) {
                [transition]
            } else {
                []
            }
        try self.init(
            elementId: container.decodeIfPresent(String.self, forKey: .elementId),
            decorator: container.decodeIfPresent(AdaptyUI.ViewConfiguration.Decorator.self, forKey: .decorator),
            padding: container.decodeIfPresent(AdaptyUI.EdgeInsets.self, forKey: .padding) ?? AdaptyUI.Element.Properties.defaultPadding,
            offset: container.decodeIfPresent(AdaptyUI.Offset.self, forKey: .offset) ?? AdaptyUI.Element.Properties.defaultOffset,
            visibility: container.decodeIfPresent(Bool.self, forKey: .visibility) ?? AdaptyUI.Element.Properties.defaultVisibility,
            transitionIn: transitionIn
        )
    }
}
