//
//  AdaptyPaywallProduct.swift
//  AdaptySDK
//
//  Created by Aleksei Valiano on 20.10.2022.
//

import StoreKit

public struct AdaptyPaywallProduct: Sendable {
    package let adaptyProductId: String

    private let underlying: any AdaptyProduct

    /// An identifier of a promotional offer, provided by Adapty for this specific user.
    public let promotionalOfferId: String?

    /// User's eligibility for the promotional offers. Check this property before displaying info about promotional offers.
    public var promotionalOfferEligibility: Bool { promotionalOfferId != nil }

    /// Same as `variationId` property of the parent AdaptyPaywall.
    public let variationId: String

    /// Same as `abTestName` property of the parent AdaptyPaywall.
    public let paywallABTestName: String

    /// Same as `name` property of the parent AdaptyPaywall.
    public let paywallName: String
}

extension AdaptyPaywallProduct: AdaptyProduct {
    public var sk1Product: SKProduct? { underlying.sk1Product }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
    public var sk2Product: Product? { underlying.sk2Product }

    public var vendorProductId: String { underlying.vendorProductId }
    public var localizedDescription: String { underlying.localizedDescription }
    public var localizedTitle: String { underlying.localizedTitle }
    public var price: Decimal { underlying.price }
    public var currencyCode: String? { underlying.currencyCode }
    public var currencySymbol: String? { underlying.currencySymbol }
    public var regionCode: String? { underlying.regionCode }
    public var isFamilyShareable: Bool { underlying.isFamilyShareable }
    public var subscriptionPeriod: AdaptyProductSubscriptionPeriod? { underlying.subscriptionPeriod }
    public var introductoryDiscount: AdaptyProductDiscount? { underlying.introductoryDiscount }
    public var subscriptionGroupIdentifier: String? { underlying.subscriptionGroupIdentifier }
    public var discounts: [AdaptyProductDiscount] { underlying.discounts }
    public func discount(byIdentifier id: String) -> AdaptyProductDiscount? { underlying.discount(byIdentifier: id) }
    public var localizedPrice: String? { underlying.localizedPrice }
    public var localizedSubscriptionPeriod: String? { underlying.localizedSubscriptionPeriod }
}

extension AdaptyPaywallProduct: CustomStringConvertible {
    public var description: String {
        "(paywallName: \(paywallName), adaptyProductId: \(adaptyProductId), variationId: \(variationId), paywallABTestName: \(paywallABTestName)"
            + (promotionalOfferId.map { ", promotionalOfferId: \($0)" } ?? "")
            + ", product:\(underlying.description)"
    }
}

extension AdaptyPaywallProduct {
    init?(
        paywall: AdaptyPaywall,
        underlying: any AdaptyProduct
    ) {
        let vendorId = underlying.vendorProductId
        guard let reference = paywall.products.first(where: { $0.vendorId == vendorId }) else {
            return nil
        }

        self.init(paywall: paywall, productReference: reference, underlying: underlying)
    }

    private init(
        paywall: AdaptyPaywall,
        productReference: AdaptyPaywall.ProductReference,
        underlying: any AdaptyProduct
    ) {
        self.init(
            adaptyProductId: productReference.adaptyProductId,
            underlying: underlying,
            promotionalOfferId: productReference.promotionalOfferId,
            variationId: paywall.variationId,
            paywallABTestName: paywall.abTestName,
            paywallName: paywall.name
        )
    }
}

extension AdaptyPaywallProduct: Encodable {
    struct PrivateObject: Sendable, Decodable {
        let vendorProductId: String
        let adaptyProductId: String
        let promotionalOfferId: String?
        let variationId: String
        let paywallABTestName: String
        let paywallName: String

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: ProductCodingKeys.self)
            vendorProductId = try container.decode(String.self, forKey: .vendorProductId)
            adaptyProductId = try container.decode(String.self, forKey: .adaptyProductId)
            promotionalOfferId = try container.decodeIfPresent(String.self, forKey: .promotionalOfferId)
            variationId = try container.decode(String.self, forKey: .paywallVariationId)
            paywallABTestName = try container.decode(String.self, forKey: .paywallABTestName)
            paywallName = try container.decode(String.self, forKey: .paywallName)
        }
    }

    private enum ProductCodingKeys: String, CodingKey {
        case vendorProductId = "vendor_product_id"
        case adaptyProductId = "adapty_product_id"

        case promotionalOfferId = "promotional_offer_id"
        case paywallVariationId = "paywall_variation_id"
        case paywallABTestName = "paywall_ab_test_name"
        case paywallName = "paywall_name"

        case subscriptionDetails = "subscription_details"

        case localizedDescription = "localized_description"
        case localizedTitle = "localized_title"
        case price
        case regionCode = "region_code"
        case isFamilyShareable = "is_family_shareable"
    }

    init(from object: PrivateObject, underlying: AdaptyProduct) {
        self.init(
            adaptyProductId:  object.adaptyProductId,
            underlying: underlying,
            promotionalOfferId: object.promotionalOfferId,
            variationId: object.variationId,
            paywallABTestName: object.paywallABTestName,
            paywallName: object.paywallName
        )
    }

    private struct SubscriptionDetail: Sendable, Encodable {
        let product: AdaptyPaywallProduct

        enum CodingKeys: String, CodingKey {
            case subscriptionGroupIdentifier = "subscription_group_identifier"
            case renewalType = "renewal_type"
            case subscriptionPeriod = "subscription_period"
            case localizedSubscriptionPeriod = "localized_subscription_period"
            case introductoryOfferPhases = "introductory_offer_phases"
            case promotionalOffer = "promotional_offer"
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encodeIfPresent(product.subscriptionGroupIdentifier, forKey: .subscriptionGroupIdentifier)
            try container.encode("autorenewable", forKey: .renewalType)
            try container.encodeIfPresent(product.subscriptionPeriod, forKey: .subscriptionPeriod)
            try container.encodeIfPresent(product.localizedSubscriptionPeriod, forKey: .localizedSubscriptionPeriod)

            if let id = product.promotionalOfferId,
               let discount = product.discount(byIdentifier: id) {
                try container.encode(discount, forKey: .promotionalOffer)
            }

            if let discount = product.introductoryDiscount {
                try container.encode([discount], forKey: .introductoryOfferPhases)
            }
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: ProductCodingKeys.self)
        try container.encode(vendorProductId, forKey: .vendorProductId)
        try container.encode(adaptyProductId, forKey: .adaptyProductId)

        try container.encode(variationId, forKey: .paywallVariationId)
        try container.encode(paywallABTestName, forKey: .paywallABTestName)
        try container.encode(paywallName, forKey: .paywallName)

        try container.encode(localizedDescription, forKey: .localizedDescription)
        try container.encode(localizedTitle, forKey: .localizedTitle)
        try container.encode(Price(from: self), forKey: .price)
        try container.encodeIfPresent(regionCode, forKey: .regionCode)
        try container.encode(isFamilyShareable, forKey: .isFamilyShareable)

        if underlying.subscriptionPeriod != nil {
            try container.encode(SubscriptionDetail(product: self), forKey: .subscriptionDetails)
        }
    }
}
