//
//  AdaptyProductsViewModel.swift
//
//
//  Created by Aleksey Goncharov on 27.05.2024.
//

#if canImport(UIKit)

import Adapty
import Foundation

@available(iOS 15.0, *)
@MainActor // TODO: swift 6
protocol ProductsInfoProvider {
    func selectedProductInfo(by groupId: String) -> ProductInfoModel?
    func productInfo(by adaptyId: String) -> ProductInfoModel?
}

@available(iOS 15.0, *)
extension AdaptyProductsViewModel: ProductsInfoProvider {
    func selectedProductInfo(by groupId: String) -> ProductInfoModel? {
        guard let selectedProductId = selectedProductId(by: groupId) else { return nil }
        return productInfo(by: selectedProductId)
    }

    func productInfo(by adaptyId: String) -> ProductInfoModel? {
        let underlying = products.first(where: { $0.adaptyProductId == adaptyId })
        return underlying
    }
}

@available(iOS 15.0, *)
@MainActor // TODO: swift 6
package final class AdaptyProductsViewModel: ObservableObject {
    private let queue = DispatchQueue(label: "AdaptyUI.SDK.AdaptyProductsViewModel.Queue")

    let logId: String
    private let eventsHandler: AdaptyEventsHandler
    private let paywallViewModel: AdaptyPaywallViewModel
    private let observerModeResolver: AdaptyObserverModeResolver?

    @Published var products: [ProductInfoModel]
    @Published var selectedProductsIds: [String: String]
    @Published var productsLoadingInProgress: Bool = false
    @Published var purchaseInProgress: Bool = false
    @Published var restoreInProgress: Bool = false

    var adaptyProducts: [AdaptyPaywallProduct]? {
        didSet {
            products = Self.generateProductsInfos(
                paywall: paywallViewModel.paywall,
                products: adaptyProducts,
                eligibilities: introductoryOffersEligibilities
            )
        }
    }

    var introductoryOffersEligibilities: [String: AdaptyEligibility]? {
        didSet {
            products = Self.generateProductsInfos(
                paywall: paywallViewModel.paywall,
                products: adaptyProducts,
                eligibilities: introductoryOffersEligibilities
            )
        }
    }

    package init(
        eventsHandler: AdaptyEventsHandler,
        paywallViewModel: AdaptyPaywallViewModel,
        products: [AdaptyPaywallProduct]?,
        introductoryOffersEligibilities: [String: AdaptyEligibility]?,
        observerModeResolver: AdaptyObserverModeResolver?
    ) {
        self.logId = eventsHandler.logId
        self.eventsHandler = eventsHandler
        self.paywallViewModel = paywallViewModel

        self.introductoryOffersEligibilities = introductoryOffersEligibilities
        self.products = Self.generateProductsInfos(
            paywall: paywallViewModel.paywall,
            products: products,
            eligibilities: introductoryOffersEligibilities
        )

        selectedProductsIds = paywallViewModel.viewConfiguration.selectedProducts

        self.observerModeResolver = observerModeResolver
    }

    private static func generateProductsInfos(
        paywall _: AdaptyPaywallInterface,
        products: [AdaptyPaywallProduct]?,
        eligibilities: [String: AdaptyEligibility]?
    ) -> [ProductInfoModel] {
        guard let products else { return [] }

        return products.map {
            RealProductInfo(
                underlying: $0,
                introEligibility: eligibilities?[$0.vendorProductId] ?? .ineligible
            )
        }
    }

    func loadProductsIfNeeded() {
        guard !productsLoadingInProgress else { return }

        guard adaptyProducts != nil, introductoryOffersEligibilities == nil else {
            loadProducts()
            return
        }

        loadProductsIntroductoryEligibilities()
    }

    func selectedProductId(by groupId: String) -> String? {
        selectedProductsIds[groupId]
    }

    func selectProduct(id: String, forGroupId groupId: String) {
        selectedProductsIds[groupId] = id

        if let selectedProduct = adaptyProducts?.first(where: { $0.adaptyProductId == id }) {
            eventsHandler.event_didSelectProduct(selectedProduct)
        }
    }

    func unselectProduct(forGroupId groupId: String) {
        selectedProductsIds.removeValue(forKey: groupId)
    }

    private func loadProducts() {
        productsLoadingInProgress = true
        let logId = logId
        Log.ui.verbose("#\(logId)# loadProducts begin")

        // TODO: swift 6
//        queue.async { [weak self] in
//            guard let self else { return }
//
//            self.paywallViewModel.paywall.getPaywallProducts { [weak self] result in
//                switch result {
//                case let .success(products):
//                    Log.ui.verbose("#\(logId)# loadProducts success")
//
//                    self?.adaptyProducts = products
//                    self?.productsLoadingInProgress = false
//                    self?.loadProductsIntroductoryEligibilities()
//                case let .failure(error):
//                    Log.ui.error("#\(logId)# loadProducts fail: \(error)")
//                    self?.productsLoadingInProgress = false
//
//                    if self?.eventsHandler.event_didFailLoadingProducts(with: error) ?? false {
//                        self?.queue.asyncAfter(deadline: .now() + .seconds(2)) { [weak self] in
//                            self?.loadProducts()
//                        }
//                    }
//                }
//            }
//        }
    }

    private func loadProductsIntroductoryEligibilities() {
        guard let products = adaptyProducts else { return }

        let logId = logId
        Log.ui.verbose("#\(logId)# loadProductsIntroductoryEligibilities begin")

        // TODO: swift 6
//        Adapty.getProductsIntroductoryOfferEligibility(products: products) { [weak self] result in
//            switch result {
//            case let .success(eligibilities):
//                self?.introductoryOffersEligibilities = eligibilities
//                Log.ui.verbose("#\(logId)# loadProductsIntroductoryEligibilities success: \(eligibilities)")
//            case let .failure(error):
//                Log.ui.error("#\(logId)# loadProductsIntroductoryEligibilities fail: \(error)")
//            }
//        }
    }

    private func handlePurchasedResult(
        underlying: AdaptyPaywallProduct,
        result: AdaptyResult<AdaptyPurchasedInfo>
    ) {
        switch result {
        case let .success(info):
            eventsHandler.event_didFinishPurchase(underlying: underlying, purchasedInfo: info)
        case let .failure(error):
            if error.adaptyErrorCode == .paymentCancelled {
                eventsHandler.event_didCancelPurchase(underlying: underlying)
            } else {
                eventsHandler.event_didFailPurchase(underlying: underlying, error: error)
            }
        }
    }

    private func handleRestoreResult(result: AdaptyResult<AdaptyProfile>) {
        switch result {
        case let .success(profile):
            eventsHandler.event_didFinishRestore(with: profile)
        case let .failure(error):
            eventsHandler.event_didFailRestore(with: error)
        }
    }

    // MARK: Actions

    func purchaseSelectedProduct(fromGroupId groupId: String) {
        guard let productId = selectedProductId(by: groupId) else { return }
        purchaseProduct(id: productId)
    }

    func purchaseProduct(id productId: String) {
        guard let underlying = adaptyProducts?.first(where: { $0.adaptyProductId == productId }) else { return }
        let logId = logId
        if let observerModeResolver {
            observerModeResolver.observerMode(
                didInitiatePurchase: underlying,
                onStartPurchase: { [weak self] in
                    Log.ui.verbose("#\(logId)# observerDidStartPurchase")
                    self?.purchaseInProgress = true
                },
                onFinishPurchase: { [weak self] in
                    Log.ui.verbose("#\(logId)# observerDidFinishPurchase")
                    self?.purchaseInProgress = false
                }
            )
        } else {
            eventsHandler.event_didStartPurchase(underlying: underlying)
            purchaseInProgress = true

            // TODO: swift 6
//            Adapty.makePurchase(underlying: underlying) { [weak self] result in
//                self?.handlePurchasedResult(underlying: underlying, result: result)
//                self?.purchaseInProgress = false
//            }
        }
    }

    func restorePurchases() {
        eventsHandler.event_didStartRestore()

        restoreInProgress = true
        // TODO: swift 6
//        Adapty.restorePurchases { [weak self] result in
//            self?.handleRestoreResult(result: result)
//            self?.restoreInProgress = false
//        }
    }
}

#endif
