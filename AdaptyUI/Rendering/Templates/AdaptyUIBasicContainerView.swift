//
//  AdaptyUIBasicContainerView.swift
//
//
//  Created by Aleksey Goncharov on 03.05.2024.
//
#if canImport(UIKit)

import Adapty
import SwiftUI

@available(iOS 15.0, *)
extension CoordinateSpace {
    static let adaptyBasicName = "adapty.container.basic"
    static let adaptyBasic = CoordinateSpace.named(adaptyBasicName)
}

@available(iOS 15.0, *)
struct AdaptyUIBasicContainerView: View {
    @EnvironmentObject
    private var paywallViewModel: AdaptyPaywallViewModel
    @Environment(\.adaptyScreenSize)
    private var screenSize: CGSize
    @Environment(\.adaptySafeAreaInsets)
    private var safeArea: EdgeInsets
    @State
    private var footerSize: CGSize = .zero
    @State
    private var drawFooterBackground = false

    var screen: AdaptyUI.Screen

    var body: some View {
        GeometryReader { globalProxy in
            ZStack(alignment: .bottom) {
                if let coverBox = screen.cover, let coverContent = coverBox.content {
                    ScrollView {
                        VStack(spacing: 0) {
                            coverView(
                                coverBox,
                                coverContent,
                                nil
                            )

                            contentView(
                                content: screen.content,
                                coverBox: coverBox,
                                globalProxy: globalProxy
                            )
                        }
                    }
                    .ignoresSafeArea()
                    .scrollIndicatorsHidden_compatible()
                } else {
                    EmptyView()
                        .onAppear {
                            paywallViewModel.eventsHandler.event_didFailRendering(
                                with: .wrongComponentType("screen.cover")
                            )
                        }
                }

                if let footer = screen.footer {
                    footerView(footer, globalProxy: globalProxy)
                        .onGeometrySizeChange { footerSize = $0 }
                }

                if let overlay = screen.overlay {
                    AdaptyUIElementView(overlay)
                }
            }
            .coordinateSpace(name: CoordinateSpace.adaptyBasicName)
            .ignoresSafeArea()
        }
        .coordinateSpace(name: CoordinateSpace.adaptyGlobalName)
    }

    @ViewBuilder
    func coverView(
        _ box: AdaptyUI.Box,
        _ content: AdaptyUI.Element,
        _ properties: AdaptyUI.Element.Properties?
    ) -> some View {
        let height: CGFloat = {
            if let boxHeight = box.height, case let .fixed(unit) = boxHeight {
                return unit.points(screenSize: screenSize.height, safeAreaStart: safeArea.top, safeAreaEnd: safeArea.bottom)
            } else {
                return 0.0
            }
        }()

        GeometryReader { p in
            let minY = p.frame(in: .adaptyBasic).minY
            let isScrollingDown = minY > 0
            let isScrollingUp = minY < 0
            let scale = max(1.0, 1.0 + minY / p.size.height)

            AdaptyUIElementView(content)
                .frame(
                    width: p.size.width,
                    height: {
                        if isScrollingDown {
                            return height + minY
                        } else {
                            return height
                        }
                    }()
                )
                .scaleEffect(x: scale, y: scale, anchor: .center)
                .clipped()
                .offset(
                    y: {
                        if isScrollingUp {
                            return -minY / 2.0
                        } else if isScrollingDown {
                            return -minY
                        } else {
                            return 0.0
                        }
                    }()
                )
        }
        .frame(height: height)
    }

    @ViewBuilder
    func contentView(
        content: AdaptyUI.Element,
        coverBox: AdaptyUI.Box,
        globalProxy: GeometryProxy
    ) -> some View {
        let coverHeight: CGFloat = {
            if let boxHeight = coverBox.height, case let .fixed(unit) = boxHeight {
                return unit.points(screenSize: screenSize.height, safeAreaStart: safeArea.top, safeAreaEnd: safeArea.bottom)
            } else {
                return 0.0
            }
        }()

        let bottomOverscrollHeight = screenSize.height
        let properties = content.properties
        let selfHeight = screenSize.height - coverHeight
        let offsetY = properties?.offset.y ?? 0

        VStack(spacing: 0) {
            AdaptyUIElementWithoutPropertiesView(content)

            FooterVerticalFillerView(height: footerSize.height) { frame in
                withAnimation {
                    drawFooterBackground = frame.maxY > globalProxy.size.height + globalProxy.safeAreaInsets.bottom
                }
            }
        }
        .padding(.bottom, bottomOverscrollHeight - offsetY)
        .applyingProperties(properties, includeBackground: true)
        .padding(.bottom, offsetY - bottomOverscrollHeight)
    }

    @ViewBuilder
    private func footerView(
        _ element: AdaptyUI.Element,
        globalProxy: GeometryProxy
    ) -> some View {
        if footerSize.height >= globalProxy.size.height {
            ScrollView {
                AdaptyUIElementView(element, drawDecoratorBackground: drawFooterBackground)
            }
            .scrollIndicatorsHidden_compatible()
        } else {
            AdaptyUIElementView(element, drawDecoratorBackground: drawFooterBackground)
        }
    }
}

#endif
