//
//  AdaptyUIActionsViewModel.swift
//
//
//  Created by Aleksey Goncharov on 21.05.2024.
//

#if canImport(UIKit)

import Adapty
import SwiftUI

@available(iOS 15.0, *)
package class AdaptyUIActionsViewModel: ObservableObject {
    let eventsHandler: AdaptyEventsHandler

    package init(eventsHandler: AdaptyEventsHandler) {
        self.eventsHandler = eventsHandler
    }

//    func actionOccured(_ action: AdaptyUI.Action) {
//        eventsHandler.log(.verbose, "actionOccured \(action)")
//        onActionOccured?(action)
//    }
//    
    func closeActionOccured() {
        eventsHandler.event_didPerformAction(.close)
    }
    
    func openUrlActionOccured(url urlString: String?) {
        guard let urlString, let url = URL(string: urlString) else {
            eventsHandler.log(.warn, "can't parse url: \(urlString ?? "null")")
            return
        }
        eventsHandler.event_didPerformAction(.openURL(url: url))
    }
    
    func customActionOccured(id: String) {
        eventsHandler.event_didPerformAction(.custom(id: id))
    }
}

#endif
