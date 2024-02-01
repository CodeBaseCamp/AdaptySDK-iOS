//
//  SKProductsManager+PurchasedSK2Transaction.swift
//  AdaptySDK
//
//  Created by Aleksei Valiano on 01.06.2023
//

import StoreKit

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
extension SKProductsManager {
    func fillPurchasedTransaction(variationId: String?,
                                  persistentVariationId: String? = nil,
                                  purchasedSK2Transaction transaction: SK2Transaction,
                                  _ completion: @escaping (PurchasedTransaction) -> Void) {
        let productId = transaction.productID

        fetchSK2Product(productIdentifier: productId, fetchPolicy: .returnCacheDataElseLoad) { result in
            if let error = result.error {
                Log.error("SKQueueManager: fetch SK2Product \(productId) error: \(error)")
            }
            completion(PurchasedTransaction(
                product: try? result.get(),
                variationId: variationId,
                persistentVariationId: persistentVariationId,
                purchasedSK2Transaction: transaction
            ))
        }
    }
}

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
private extension PurchasedTransaction {
    init(
        product: Product?,
        variationId: String?,
        persistentVariationId: String?,
        purchasedSK2Transaction transaction: SK2Transaction
    ) {
        var subscriptionOffer: PurchasedTransaction.SubscriptionOffer?

        if #available(iOS 17.2, macOS 14.2, tvOS 17.2, watchOS 10.2, visionOS 1.1, *) {
            subscriptionOffer = .init(transaction.offer, product: product)
        } else {
            subscriptionOffer = .init(transaction, product: product)
        }

        self.init(
            transactionId: transaction.transactionIdentifier,
            originalTransactionId: transaction.originalTransactionIdentifier,
            vendorProductId: transaction.productID,
            productVariationId: variationId,
            persistentProductVariationId: persistentVariationId,
            price: product?.price,
            priceLocale: product?.priceFormatStyle.locale.a_currencyCode,
            storeCountry: product?.priceFormatStyle.locale.regionCode,
            subscriptionOffer: subscriptionOffer,
            environment: transaction.environmentString
        )
    }
}

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
private extension PurchasedTransaction.SubscriptionOffer {
    init?(_ transaction: SK2Transaction, product: Product?) {
        guard let offerType = transaction.offerType else { return nil }
        let productOffer = product?.subscriptionOffer(byType: offerType, withId: transaction.offerID)
        self = .init(
            id: transaction.offerID,
            period: (productOffer?.period).map { AdaptyProductSubscriptionPeriod(subscriptionPeriod: $0) },
            paymentMode: (productOffer?.paymentMode).map { .init(mode: $0) } ?? .unknown,
            type: .init(type: offerType),
            price: productOffer?.price
        )
    }

    @available(iOS 17.2, macOS 14.2, tvOS 17.2, watchOS 10.2, visionOS 1.1, *)
    init?(_ transactionOffer: SK2Transaction.Offer?, product: Product?) {
        guard let transactionOffer = transactionOffer else { return nil }
        let productOffer = product?.subscriptionOffer(byType: transactionOffer.type, withId: transactionOffer.id)
        self = .init(
            id: transactionOffer.id,
            period: (productOffer?.period).map { .init(subscriptionPeriod: $0) },
            paymentMode: transactionOffer.paymentMode.map { .init(mode: $0) } ?? .unknown,
            type: .init(type: transactionOffer.type),
            price: productOffer?.price
        )
    }
}

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
private extension Product {
    func subscriptionOffer(
        byType offerType: SK2Transaction.OfferType,
        withId offerId: String?
    ) -> Product.SubscriptionOffer? {
        guard let subscription = subscription else { return nil }

        switch offerType {
        case .introductory:
            return subscription.introductoryOffer
        case .promotional:
            if let offerId = offerId {
                return subscription.promotionalOffers.first(where: { $0.id == offerId })
            }
        default:
            return nil
        }
        return nil
    }
}
