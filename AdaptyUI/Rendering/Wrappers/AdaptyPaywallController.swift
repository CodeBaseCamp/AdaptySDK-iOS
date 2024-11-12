//
//  AdaptyPaywallController.swift
//
//
//  Created by Alexey Goncharov on 2023-01-17.
//

#if canImport(UIKit)

import Adapty
import SwiftUI
import UIKit

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
public final class AdaptyPaywallController: UIViewController {
    public let id = UUID()

    public let paywall: AdaptyPaywall
    public var viewConfiguration: AdaptyUI.LocalizedViewConfiguration {
        paywallConfiguration.paywallViewModel.viewConfiguration
    }

    let paywallConfiguration: AdaptyUI.PaywallConfiguration
    let showDebugOverlay: Bool

    public weak var delegate: AdaptyPaywallControllerDelegate?

    private let logId: String = Log.stamp

    init(
        paywallConfiguration: AdaptyUI.PaywallConfiguration,
        paywall: AdaptyPaywall,
        delegate: AdaptyPaywallControllerDelegate?,
        showDebugOverlay: Bool
    ) {
        self.paywallConfiguration = paywallConfiguration
        self.paywall = paywall
        self.delegate = delegate
        self.showDebugOverlay = showDebugOverlay

        super.init(nibName: nil, bundle: nil)

        modalPresentationStyle = .fullScreen
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    deinit {
        Log.ui.verbose("#\(logId)# deinit")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        Log.ui.verbose("#\(logId)# viewDidLoad begin")

        view.backgroundColor = .systemBackground

        paywallConfiguration.eventsHandler.didPerformAction = { [weak self] action in
            guard let self else { return }
            self.delegate?.paywallController(self, didPerform: action)
        }

        paywallConfiguration.eventsHandler.didSelectProduct = { [weak self] underlying in
            guard let self else { return }
            self.delegate?.paywallController(self, didSelectProduct: underlying)
        }

        paywallConfiguration.eventsHandler.didStartPurchase = { [weak self] underlying in
            guard let self else { return }
            self.delegate?.paywallController(self, didStartPurchase: underlying)
        }

        paywallConfiguration.eventsHandler.didFinishPurchase = { [weak self] underlying, purchaseResult in
            guard let self else { return }
            self.delegate?.paywallController(
                self,
                didFinishPurchase: underlying,
                purchaseResult: purchaseResult
            )
        }

        paywallConfiguration.eventsHandler.didFailPurchase = { [weak self] underlying, error in
            guard let self else { return }
            self.delegate?.paywallController(self, didFailPurchase: underlying, error: error)
        }

        paywallConfiguration.eventsHandler.didStartRestore = { [weak self] in
            guard let self else { return }
            self.delegate?.paywallControllerDidStartRestore(self)
        }

        paywallConfiguration.eventsHandler.didFinishRestore = { [weak self] profile in
            guard let self else { return }
            self.delegate?.paywallController(self, didFinishRestoreWith: profile)
        }

        paywallConfiguration.eventsHandler.didFailRestore = { [weak self] error in
            guard let self else { return }
            self.delegate?.paywallController(self, didFailRestoreWith: error)
        }

        paywallConfiguration.eventsHandler.didFailRendering = { [weak self] error in
            guard let self else { return }
            self.delegate?.paywallController(self, didFailRenderingWith: error)
        }

        paywallConfiguration.eventsHandler.didFailLoadingProducts = { [weak self] error in
            guard let self else { return false }
            guard let delegate = self.delegate else { return true }
            return delegate.paywallController(self, didFailLoadingProductsWith: error)
        }

        paywallConfiguration.eventsHandler.didPartiallyLoadProducts = { [weak self] failedIds in
            guard let self else { return }
            self.delegate?.paywallController(self, didPartiallyLoadProducts: failedIds)
        }

        addSubSwiftUIView(
            AdaptyPaywallView_Internal(
                showDebugOverlay: showDebugOverlay
            )
            .environmentObject(paywallConfiguration.paywallViewModel)
            .environmentObject(paywallConfiguration.productsViewModel)
            .environmentObject(paywallConfiguration.actionsViewModel)
            .environmentObject(paywallConfiguration.sectionsViewModel)
            .environmentObject(paywallConfiguration.tagResolverViewModel)
            .environmentObject(paywallConfiguration.timerViewModel)
            .environmentObject(paywallConfiguration.screensViewModel)
            .environmentObject(paywallConfiguration.videoViewModel),
            to: view
        )

        Log.ui.verbose("#\(logId)# viewDidLoad end")
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        Log.ui.verbose("#\(logId)# viewDidAppear")
        
        paywallConfiguration.paywallViewModel.logShowPaywall()
    }

    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        Log.ui.verbose("#\(logId)# viewDidDisappear")
        
        paywallConfiguration.paywallViewModel.resetLogShowPaywall()
    }
}

#endif
