//
//  FetchPaywallRequest.swift
//  AdaptySDK
//
//  Created by Aleksei Valiano on 23.09.2022.
//

import Foundation

private struct FetchPaywallOldRequest: HTTPRequestWithDecodableResponse {
    typealias ResponseBody = Backend.Response.Body<AdaptyPaywall>

    let endpoint: HTTPEndpoint
    let headers: Headers

    init(apiKeyPrefix: String, profileId: String, placementId: String, locale: AdaptyLocale, md5Hash: String) {
        endpoint = HTTPEndpoint(
            method: .get,
            path: "/sdk/in-apps/\(apiKeyPrefix)/paywall/\(placementId)/\(md5Hash)/"
        )

        headers = Headers()
            .setPaywallLocale(locale)
            .setBackendProfileId(profileId)
    }
}

extension HTTPSession {
    func performFetchPaywallOldRequest(
        apiKeyPrefix: String,
        profileId: String,
        placementId: String,
        locale: AdaptyLocale?,
        segmentId: String,
        _ completion: @escaping AdaptyResultCompletion<VH<AdaptyPaywall>>
    ) {
        let locale = locale ?? AdaptyLocale.defaultPaywallLocale

        let md5Hash = "{\"locale\":\"\(locale.id.lowercased())\",\"segment_hash\":\"\(segmentId)\",\"store\":\"app_store\"}".md5.hexString

        let request = FetchPaywallOldRequest(
            apiKeyPrefix: apiKeyPrefix,
            profileId: profileId,
            placementId: placementId,
            locale: locale,
            md5Hash: md5Hash
        )

        perform(
            request,
            logName: "get_paywall",
            logParams: [
                "api_prefix": .value(apiKeyPrefix),
                "placement_id": .value(placementId),
                "locale": .value(locale),
                "segment_id": .value(segmentId),
                "md5": .value(md5Hash),
            ]
        ) { (result: FetchPaywallOldRequest.Result) in
            switch result {
            case let .failure(error):
                completion(.failure(error.asAdaptyError))
            case let .success(response):
                completion(.success(VH(response.body.value, time: Date())))
            }
        }
    }
}
