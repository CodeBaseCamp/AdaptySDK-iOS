//
//  SK2ProductsFetcher.swift
//  AdaptySDK
//
//  Created by Aleksei Valiano on 25.04.2023
//

import StoreKit

private let log = Log.Category(name: "SK2ProductsFetcher")


@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
actor SK2ProductsFetcher {
    private var sk2Products = [String: SK2Product]()

    func fetchProducts(productIdentifiers productIds: Set<String>, fetchPolicy: SKProductsManager.ProductsFetchPolicy = .default, retryCount _: Int = 3) async throws -> [SK2Product] {
        guard !productIds.isEmpty else {
            throw SKManagerError.noProductIDsFound().asAdaptyError
        }

        if fetchPolicy == .returnCacheDataElseLoad {
            let products = productIds.compactMap { self.sk2Products[$0] }
            if products.count == productIds.count {
                return products
            }
        }

        log.verbose("Called SK2Product.products productIds:\(productIds)")

        let stamp = Log.stamp
        let methodName = "fetch_sk2_products"
        Adapty.trackSystemEvent(AdaptyAppleRequestParameters(
            methodName: methodName,
            stamp: stamp,
            params: [
                "products_ids": productIds,
            ]
        ))

        let sk2Products: [SK2Product]
        do {
            sk2Products = try await SK2Product.products(for: productIds)
        } catch {
            log.error("Can't fetch products from Store \(error)")

            Adapty.trackSystemEvent(AdaptyAppleResponseParameters(
                methodName: methodName,
                stamp: stamp,
                error: "\(error.localizedDescription). Detail: \(error)"
            ))

            throw SKManagerError.requestSK2ProductsFailed(error).asAdaptyError
        }

        if sk2Products.isEmpty {
            log.verbose("fetch result is empty")
        }

        for sk2Product in sk2Products {
            log.verbose("found product \(sk2Product.id) \(sk2Product.displayName) \(sk2Product.displayPrice)")
        }

        Adapty.trackSystemEvent(AdaptyAppleResponseParameters(
            methodName: methodName,
            stamp: stamp,
            params: [
                "products_ids": sk2Products.map { $0.id },
            ]
        ))

        guard !sk2Products.isEmpty else {
            throw SKManagerError.noProductIDsFound().asAdaptyError
        }

        sk2Products.forEach { self.sk2Products[$0.id] = $0 }

        return sk2Products
    }
}
