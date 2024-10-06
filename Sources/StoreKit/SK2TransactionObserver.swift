//
//  SK2TransactionObserver.swift
//  AdaptySDK
//
//  Created by Aleksei Valiano on 23.05.2023
//

import StoreKit

private let log = Log.Category(name: "SK2TransactionObserver")

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
actor SK2TransactionObserver {
    private var updates: Task<Void, Never>?
    private let productsManager: SK2ProductsManager
    private let purchaseValidator: PurchaseValidator

    init(productsManager: SK2ProductsManager, purchaseValidator: PurchaseValidator) {
        self.purchaseValidator = purchaseValidator
        self.productsManager = productsManager
        self.updates = Task(priority: .utility) { await observing()  }

        @Sendable
        func observing() async {
            for await verificationResult in SK2Transaction.updates {
                switch verificationResult {
                case let .unverified(transaction, error):
                    log.error("Transaction \(transaction.id) (originalID: \(transaction.originalID),  productID: \(transaction.productID)) is unverified. Error: \(error.localizedDescription)")
                    continue
                case let .verified(transaction):
                    log.debug("Transaction \(transaction.id) (originalID: \(transaction.originalID),  productID: \(transaction.productID), revocationDate:\(transaction.revocationDate?.description ?? "nil"), expirationDate:\(transaction.expirationDate?.description ?? "nil") \((transaction.expirationDate.map { $0 < Date() } ?? false) ? "[expired]" : "") , isUpgraded:\(transaction.isUpgraded) ) ")

                    guard transaction.justPurchasedRenewed else { return }

                    let purchasedTransaction = await productsManager.fillPurchasedTransaction(variationId: nil, purchasedSK2Transaction: transaction)

                    _ = try? await purchaseValidator.validatePurchase(transaction: purchasedTransaction, reason: .observing)
                }
            }
        }
    }

    deinit {
        updates?.cancel()
        updates = nil
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
private extension SK2Transaction {
    var justPurchasedRenewed: Bool {
        if revocationDate != nil {
            return false
        } else if let expirationDate, expirationDate < Date() {
            return false
        } else if isUpgraded {
            return false
        }

        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
            if reason == .renewal { return false }
        }

        return true
    }
}
