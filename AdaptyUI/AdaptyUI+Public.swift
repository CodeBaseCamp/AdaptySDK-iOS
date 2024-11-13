//
//  AdaptyPaywallControllerDelegate.swift
//
//
//  Created by Alexey Goncharov on 27.1.23..
//

import Adapty

/// AdaptyUI is a module intended to display paywalls created with the Paywall Builder.
/// To make full use of this functionality, you need to install an additional library, as well as make additional setups in the Adapty Dashboard.
/// You can find more information in the corresponding section of [our documentation](https://adapty.io/docs/3.0/adapty-paywall-builder).
public enum AdaptyUI {}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
public extension AdaptyUI {
    struct Configuration: Sendable {
        public static let `default` = Configuration(mediaCacheConfiguration: nil)

        /// Represents the Media Cache configuration used in AdaptyUI
        let mediaCacheConfiguration: MediaCacheConfiguration?

        public init(
            mediaCacheConfiguration: MediaCacheConfiguration?
        ) {
            self.mediaCacheConfiguration = mediaCacheConfiguration
        }
    }
}

#if canImport(UIKit)

import UIKit

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
public extension AdaptyUI {
    /// This enum describes user initiated actions.
    enum Action {
        /// User pressed Close Button
        case close
        /// User pressed any button with URL
        case openURL(url: URL)
        /// User pressed any button with custom action (e.g. login)
        case custom(id: String)
    }
}

/// Implement this protocol to respond to different events happening inside the purchase screen.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
@MainActor
public protocol AdaptyPaywallControllerDelegate: NSObject {
    /// If user performs an action process, this method will be invoked.
    ///
    /// - Parameters:
    ///     - controller: an ``AdaptyPaywallController`` within which the event occurred.
    ///     - action: an ``AdaptyUI.Action`` value.
    func paywallController(
        _ controller: AdaptyPaywallController,
        didPerform action: AdaptyUI.Action
    )

    /// If product was selected for purchase (by user or by system), this method will be invoked.
    ///
    /// - Parameters:
    ///     - controller: an ``AdaptyPaywallController`` within which the event occurred.
    ///     - product: an ``AdaptyPaywallProduct`` which was selected.
    func paywallController(
        _ controller: AdaptyPaywallController,
        didSelectProduct product: AdaptyPaywallProductWithoutDeterminingOffer
    )

    /// If user initiates the purchase process, this method will be invoked.
    ///
    /// - Parameters:
    ///     - controller: an ``AdaptyPaywallController`` within which the event occurred.
    ///     - product: an ``AdaptyPaywallProduct`` of the purchase.
    func paywallController(
        _ controller: AdaptyPaywallController,
        didStartPurchase product: AdaptyPaywallProduct
    )

    /// This method is invoked when a successful purchase is made.
    ///
    /// The default implementation is simply dismissing the controller:
    /// ```
    /// controller.dismiss(animated: true)
    /// ```
    /// - Parameters:
    ///   - controller: an ``AdaptyPaywallController`` within which the event occurred.
    ///   - product: an ``AdaptyPaywallProduct`` of the purchase.
    ///   - purchaseResult: an ``AdaptyPurchaseResult`` object containing up to date information about successful purchase.
    func paywallController(
        _ controller: AdaptyPaywallController,
        didFinishPurchase product: AdaptyPaywallProduct,
        purchaseResult: AdaptyPurchaseResult
    )

    /// This method is invoked when the purchase process fails.
    /// - Parameters:
    ///   - controller: an ``AdaptyPaywallController`` within which the event occurred.
    ///   - product: an ``AdaptyPaywallProduct`` of the purchase.
    ///   - error: an ``AdaptyError`` object representing the error.
    func paywallController(
        _ controller: AdaptyPaywallController,
        didFailPurchase product: AdaptyPaywallProduct,
        error: AdaptyError
    )

    /// If user initiates the restore process, this method will be invoked.
    ///
    /// - Parameters:
    ///     - controller: an ``AdaptyPaywallController`` within which the event occurred.
    func paywallControllerDidStartRestore(_ controller: AdaptyPaywallController)

    /// This method is invoked when a successful restore is made.
    ///
    /// Check if the ``AdaptyProfile`` object contains the desired access level, and if so, the controller can be dismissed.
    /// ```
    /// controller.dismiss(animated: true)
    /// ```
    ///
    /// - Parameters:
    ///   - controller: an ``AdaptyPaywallController`` within which the event occurred.
    ///   - profile: an ``AdaptyProfile`` object containing up to date information about the user.
    func paywallController(
        _ controller: AdaptyPaywallController,
        didFinishRestoreWith profile: AdaptyProfile
    )

    /// This method is invoked when the restore process fails.
    /// - Parameters:
    ///   - controller: an ``AdaptyPaywallController`` within which the event occurred.
    ///   - error: an ``AdaptyError`` object representing the error.
    func paywallController(
        _ controller: AdaptyPaywallController,
        didFailRestoreWith error: AdaptyError
    )

    /// This method will be invoked in case of errors during the screen rendering process.
    /// - Parameters:
    ///   - controller: an ``AdaptyPaywallController`` within which the event occurred.
    ///   - error: an ``AdaptyError`` object representing the error.
    func paywallController(
        _ controller: AdaptyPaywallController,
        didFailRenderingWith error: AdaptyError
    )

    /// This method is invoked in case of errors during the products loading process.
    /// - Parameters:
    ///   - controller: an ``AdaptyPaywallController`` within which the event occurred.
    ///   - error: an ``AdaptyError`` object representing the error.
    /// - Returns: Return `true`, if you want to retry products fetching.
    func paywallController(
        _ controller: AdaptyPaywallController,
        didFailLoadingProductsWith error: AdaptyError
    ) -> Bool

    /// This method is invoked if there was a propblem with loading a subset of paywall's products.
    /// - Parameters:
    ///   - controller: an ``AdaptyPaywallController`` within which the event occurred.
    ///   - failedIds: an array with product ids which was failed to load.
    /// - Returns: Return `true`, if you want to retry products fetching.
    func paywallController(
        _ controller: AdaptyPaywallController,
        didPartiallyLoadProducts failedIds: [String]
    )
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
public protocol AdaptyObserverModeResolver {
    func observerMode(
        didInitiatePurchase product: AdaptyPaywallProduct,
        onStartPurchase: @escaping () -> Void,
        onFinishPurchase: @escaping () -> Void
    )
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
@MainActor
public extension AdaptyUI {
    private static var isActivated: Bool = false
    internal static var isObserverModeEnabled: Bool = false

    /// Use this method to initialize the AdaptyUI SDK.
    ///
    /// Call this method in the `application(_:didFinishLaunchingWithOptions:)` right after `Adapty.activate()`.
    ///
    /// - Parameter builder: `AdaptyUI.Configuration` which allows to configure AdaptyUI SDK
    static func activate(configuration: AdaptyUI.Configuration = .default) async throws {
        let sdk: Adapty
        do {
            sdk = try await Adapty.activatedSDK
        } catch {
            let err = AdaptyUIError.adaptyNotActivatedError
            Log.ui.error("AdaptyUI activate error: \(err)")
            throw err
        }

        guard !AdaptyUI.isActivated else {
            let err = AdaptyUIError.activateOnceError
            Log.ui.warn("AdaptyUI activate error: \(err)")

            throw err
        }
        AdaptyUI.isActivated = true
        AdaptyUI.isObserverModeEnabled = await sdk.observerMode

        AdaptyUI.configureMediaCache(configuration.mediaCacheConfiguration ?? .default)
        ImageUrlPrefetcher.shared.initialize()

        Log.ui.info("AdaptyUI activated with \(configuration)")
    }

    /// If you are using the [Paywall Builder](https://adapty.io/docs/3.0/adapty-paywall-builder), you can use this method to get a configuration object for your paywall.
    ///
    /// - Parameters:
    ///   - forPaywall: the ``AdaptyPaywall`` for which you want to get a configuration.
    ///   - loadTimeout: the `TimeInterval` value which limits the request time. Cached or Fallback result will be returned in case of timeout exeeds.
    /// - Returns: The ``AdaptyUI.LocalizedViewConfiguration`` object. Use it with [AdaptyUI](https://github.com/adaptyteam/AdaptySDK-iOS-VisualPaywalls.git) library.
    static func getViewConfiguration(
        forPaywall paywall: AdaptyPaywall,
        loadTimeout: TimeInterval = 5.0
    ) async throws -> AdaptyViewConfiguration {
        guard AdaptyUI.isActivated else {
            let err = AdaptyUIError.adaptyNotActivatedError
            Log.ui.error("AdaptyUI getViewConfiguration error: \(err)")

            throw err
        }

        return try await Adapty.getViewConfiguration(paywall: paywall, loadTimeout: loadTimeout)
    }

    /// Right after receiving ``AdaptyUI.ViewConfiguration``, you can create the corresponding ``AdaptyPaywallController`` to present it afterwards.
    ///
    /// - Parameters:
    ///   - paywall: an ``AdaptyPaywall`` object, for which you are trying to get a controller.
    ///   - products: optional ``AdaptyPaywallProducts`` array. Pass this value in order to optimize the display time of the products on the screen. If you pass `nil`, ``AdaptyUI`` will automatically fetch the required products.
    ///   - viewConfiguration: an ``AdaptyUI.LocalizedViewConfiguration`` object containing information about the visual part of the paywall. To load it, use the ``AdaptyUI.getViewConfiguration(paywall:locale:)`` method.
    ///   - delegate: the object that implements the ``AdaptyPaywallControllerDelegate`` protocol. Use it to respond to different events happening inside the purchase screen.
    ///   - observerModeResolver: if you are going to use AdaptyUI in Observer Mode, pass the resolver function here.
    ///   - tagResolver: if you are going to use custom tags functionality, pass the resolver function here.
    /// - Returns: an ``AdaptyPaywallController`` object, representing the requested paywall screen.
    static func paywallController(
        for paywall: AdaptyPaywall,
        products: [AdaptyPaywallProduct]? = nil,
        viewConfiguration: AdaptyViewConfiguration,
        delegate: AdaptyPaywallControllerDelegate,
        observerModeResolver: AdaptyObserverModeResolver? = nil,
        tagResolver: AdaptyTagResolver? = nil,
        timerResolver: AdaptyTimerResolver? = nil,
        showDebugOverlay: Bool = false
    ) throws -> AdaptyPaywallController {
        guard AdaptyUI.isActivated else {
            let err = AdaptyUIError.adaptyNotActivatedError
            Log.ui.error("AdaptyUI paywallController(for:) error: \(err)")
            throw err
        }

        let paywallConfiguration = PaywallConfiguration(
            logId: Log.stamp,
            paywall: paywall,
            viewConfiguration: viewConfiguration,
            products: products,
            observerModeResolver: observerModeResolver,
            tagResolver: tagResolver,
            timerResolver: timerResolver
        )

        return AdaptyPaywallController(
            paywallConfiguration: paywallConfiguration,
            paywall: paywall,
            delegate: delegate,
            showDebugOverlay: showDebugOverlay
        )
    }

    /// Right after receiving ``AdaptyUI.ViewConfiguration``, you can create the corresponding ``AdaptyPaywallController`` to present it afterwards.
    ///
    /// - Parameters:
    ///   - paywall: an ``AdaptyPaywall`` object, for which you are trying to get a controller.
    ///   - products: optional ``AdaptyPaywallProducts`` array. Pass this value in order to optimize the display time of the products on the screen. If you pass `nil`, ``AdaptyUI`` will automatically fetch the required products.
    ///   - viewConfiguration: an ``AdaptyUI.LocalizedViewConfiguration`` object containing information about the visual part of the paywall. To load it, use the ``AdaptyUI.getViewConfiguration(paywall:locale:)`` method.
    ///   - observerModeResolver: if you are going to use AdaptyUI in Observer Mode, pass the resolver function here.
    ///   - tagResolver: if you are going to use custom tags functionality, pass the resolver function here.
    /// - Returns: an ``AdaptyPaywallConfiguration`` object.
    static func paywallConfiguration(
        for paywall: AdaptyPaywall,
        products: [AdaptyPaywallProduct]? = nil,
        viewConfiguration: AdaptyViewConfiguration,
        observerModeResolver: AdaptyObserverModeResolver? = nil,
        tagResolver: AdaptyTagResolver? = nil,
        timerResolver: AdaptyTimerResolver? = nil
    ) -> PaywallConfiguration {
        PaywallConfiguration(
            logId: Log.stamp,
            paywall: paywall,
            viewConfiguration: viewConfiguration,
            products: products,
            observerModeResolver: observerModeResolver,
            tagResolver: tagResolver,
            timerResolver: timerResolver
        )
    }
}

#endif
