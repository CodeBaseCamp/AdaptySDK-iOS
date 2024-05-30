//
//  AdaptyUIToggleView.swift
//
//
//  Created by Aleksey Goncharov on 30.05.2024.
//

#if canImport(UIKit)

import Adapty
import SwiftUI

@available(iOS 15.0, *)
struct AdaptyUIToggleView: View {
    @EnvironmentObject var viewModel: AdaptySectionsViewModel

    private var toggle: AdaptyUI.Toggle

    init(_ toggle: AdaptyUI.Toggle) {
        self.toggle = toggle
    }

    var body: some View {
        Toggle(isOn: .init(get: {
            // TODO: check default value
            (viewModel.selectedIndex(for: toggle.sectionId) ?? toggle.offIndex) == toggle.onIndex
        }, set: { value in
            viewModel.updateSelection(for: toggle.sectionId, index: value ? toggle.onIndex : toggle.offIndex)
        })) {
            EmptyView()
        }
        .tint(toggle.color?.asColor?.swiftuiColor)
    }
}

#if DEBUG

@available(iOS 15.0, *)
#Preview {
    AdaptyUIToggleView(.create(sectionId: "toggle_preview"))
        .environmentObject(AdaptySectionsViewModel(logId: "Preview"))
}

#endif

#endif
