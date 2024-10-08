//
//  StoreKitReceiptManager.swift
//  AdaptySDK
//
//  Created by Aleksei Valiano on 05.10.2024
//

import StoreKit

private let log = Log.Category(name: "StoreKitReceiptManager")

actor StoreKitReceiptManager {
    private let session: Backend.MainExecutor
    private let refresher = ReceiptRefresher()
    private var syncing: (task: Task<VH<AdaptyProfile>?, any Error>, profileId: String)?

    init(session: Backend.MainExecutor, refreshIfEmpty: Bool = false) {
        self.session = session

        if refreshIfEmpty {
            Task {
                _ = try? await getReceipt()
            }
        }
    }

    func getReceipt() async throws -> Data {
        do {
            return try bundleReceipt()
        } catch {
            try await refresher.refresh()
            return try bundleReceipt()
        }
    }

    private func bundleReceipt() throws -> Data {
        let stamp = Log.stamp
        Task {
            await Adapty.trackSystemEvent(AdaptyAppleRequestParameters(methodName: .getReceipt, stamp: stamp))
        }
        do {
            guard let url = Bundle.main.appStoreReceiptURL else {
                log.error("Receipt URL is nil.")
                throw StoreKitManagerError.receiptIsEmpty().asAdaptyError
            }

            var data: Data
            do {
                data = try Data(contentsOf: url)
            } catch {
                log.error("The receipt data failed to load. \(error)")
                throw StoreKitManagerError.receiptIsEmpty(error).asAdaptyError
            }

            if data.isEmpty {
                log.error("The receipt data is empty.")
                throw StoreKitManagerError.receiptIsEmpty().asAdaptyError
            }

            Task {
                await Adapty.trackSystemEvent(AdaptyAppleResponseParameters(methodName: .getReceipt, stamp: stamp))
            }
            log.verbose("Loaded receipt")
            return data

        } catch {
            Task {
                await Adapty.trackSystemEvent(AdaptyAppleResponseParameters(methodName: .getReceipt, stamp: stamp, error: error.localizedDescription))
            }
            throw error
        }
    }
}

extension StoreKitReceiptManager: StoreKitTransactionManager {
    func syncTransactions(for profileId: String) async throws -> VH<AdaptyProfile>? {
        let task: Task<VH<AdaptyProfile>?, any Error>
        if let syncing, syncing.profileId == profileId {
            task = syncing.task
        } else {
            task = Task<VH<AdaptyProfile>?, any Error> {
                try await syncReceipt(for: profileId)
            }
            syncing = (task, profileId)
        }
        return try await task.value
    }

    private func syncReceipt(for profileId: String) async throws -> VH<AdaptyProfile>? {
        defer { syncing = nil }

        do {
            return try await session.validateReceipt(
                profileId: profileId,
                receipt: getReceipt()
            )
        } catch {
            throw error.asAdaptyError ?? AdaptyError.syncRecieptFailed(unknownError: error)
        }
    }
}

private final class ReceiptRefresher: NSObject, @unchecked Sendable {
    private let queue = DispatchQueue(label: "Adapty.SDK.ReceiptRefresher")
    private var refreshCompletionHandlers: [AdaptyErrorCompletion]?

    func refresh() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            refresh { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    func refresh(_ completion: @escaping AdaptyErrorCompletion) {
        queue.async { [weak self] in

            guard let self else {
                completion(StoreKitManagerError.interrupted().asAdaptyError)
                return
            }

            if let handlers = self.refreshCompletionHandlers {
                self.refreshCompletionHandlers = handlers + [completion]
                log.debug("Add handler to refreshCompletionHandlers.count = \(self.refreshCompletionHandlers?.count ?? 0)")
                return
            }

            self.refreshCompletionHandlers = [completion]

            log.verbose("Start refresh receipt")
            let request = SKReceiptRefreshRequest()
            request.delegate = self
            request.start()

            let stamp = "SKR\(request.hash)"
            Task {
                await Adapty.trackSystemEvent(AdaptyAppleRequestParameters(methodName: .refreshReceipt, stamp: stamp))
            }
        }
    }

    private func completedRefresh(_ request: SKRequest, _ error: AdaptyError? = nil) {
        let stamp = "SKR\(request.hash)"

        Task {
            await Adapty.trackSystemEvent(AdaptyAppleResponseParameters(methodName: .refreshReceipt, stamp: stamp, error: error?.description))
        }

        queue.async { [weak self] in

            guard let self else { return }

            guard let handlers = self.refreshCompletionHandlers, !handlers.isEmpty else {
                log.error("Not found refreshCompletionHandlers")
                return
            }
            self.refreshCompletionHandlers = nil

            if let error {
                log.error("Refresh receipt failed. \(error)")
            } else {
                log.verbose("Refresh receipt success.")
            }

            log.debug("Call refreshCompletionHandlers.count = \(handlers.count)\(error.map { " with error = \($0)" } ?? "")")

            handlers.forEach { $0(error) }
        }
    }
}

extension ReceiptRefresher: SKRequestDelegate {
    func requestDidFinish(_ request: SKRequest) {
        guard request is SKReceiptRefreshRequest else { return }
        completedRefresh(request)
        request.cancel()
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        guard request is SKReceiptRefreshRequest else { return }
        completedRefresh(request, StoreKitManagerError.refreshReceiptFailed(error).asAdaptyError)
        request.cancel()
    }
}
