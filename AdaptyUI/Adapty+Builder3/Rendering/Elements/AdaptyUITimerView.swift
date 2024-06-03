//
//  File.swift
//
//
//  Created by Aleksey Goncharov on 30.05.2024.
//

#if canImport(UIKit)

import Adapty
import SwiftUI

@available(iOS 15.0, *)
class AdaptyTimerViewModel: ObservableObject {}

@available(iOS 15.0, *)
extension AdaptyUI {
    enum TimerTag {
        case TIMER_h
        case TIMER_hh
        case TIMER_m
        case TIMER_mm
        case TIMER_s
        case TIMER_ss
        case TIMER_S
        case TIMER_SS
        case TIMER_SSS

        case TIMER_Total_Days(Int)
        case TIMER_Total_Hours(Int)
        case TIMER_Total_Minutes(Int)
        case TIMER_Total_Seconds(Int)
        case TIMER_Total_Milliseconds(Int)
    }
}

@available(iOS 15.0, *)
extension AdaptyUI.TimerTag {
    static func createFromString(_ value: String) -> AdaptyUI.TimerTag? {
        switch value {
        case "TIMER_h": return .TIMER_h
        case "TIMER_hh": return .TIMER_hh
        case "TIMER_m": return .TIMER_m
        case "TIMER_mm": return .TIMER_mm
        case "TIMER_s": return .TIMER_s
        case "TIMER_ss": return .TIMER_ss
        case "TIMER_S": return .TIMER_S
        case "TIMER_SS": return .TIMER_SS
        case "TIMER_SSS": return .TIMER_SSS
        default: break
        }
        
        if value.starts(with: "TIMER_Total_Days_") {
            let nString = value.replacingOccurrences(of: "TIMER_Total_Days_", with: "")
            return .TIMER_Total_Days(Int(nString) ?? 0)
        }
        
        if value.starts(with: "TIMER_Total_Hours_") {
            let nString = value.replacingOccurrences(of: "TIMER_Total_Hours_", with: "")
            return .TIMER_Total_Hours(Int(nString) ?? 0)
        }
        
        if value.starts(with: "TIMER_Total_Minutes_") {
            let nString = value.replacingOccurrences(of: "TIMER_Total_Minutes_", with: "")
            return .TIMER_Total_Minutes(Int(nString) ?? 0)
        }
        
        if value.starts(with: "TIMER_Total_Seconds_") {
            let nString = value.replacingOccurrences(of: "TIMER_Total_Seconds_", with: "")
            return .TIMER_Total_Seconds(Int(nString) ?? 0)
        }
        
        if value.starts(with: "TIMER_Total_Milliseconds_") {
            let nString = value.replacingOccurrences(of: "TIMER_Total_Milliseconds_", with: "")
            return .TIMER_Total_Milliseconds(Int(nString) ?? 0)
        }
        
        return nil
    }

    func string(for timeinterval: TimeInterval) -> String? {
        switch self {
        case .TIMER_h:
            String(format: "%.1d", Int(timeinterval / 3600.0) % 3600)
        case .TIMER_hh:
            String(format: "%.2d", Int(timeinterval / 3600.0) % 3600)
        case .TIMER_m:
            String(format: "%.1d", Int(timeinterval / 60.0) % 60)
        case .TIMER_mm:
            String(format: "%.2d", Int(timeinterval / 60.0) % 60)
        case .TIMER_s:
            String(format: "%.1d", Int(timeinterval) % 60)
        case .TIMER_ss:
            String(format: "%.2d", Int(timeinterval) % 60)
        case .TIMER_S:
            String(format: "%.1d", Int(timeinterval * 10.0) % 10)
        case .TIMER_SS:
            String(format: "%.2d", Int(timeinterval * 100.0) % 100)
        case .TIMER_SSS:
            String(format: "%.3d", Int(timeinterval * 1000.0) % 1000)
        case let .TIMER_Total_Days(n):
            String(format: "%.\(n)d", Int(timeinterval / 86400.0))
        case let .TIMER_Total_Hours(n):
            String(format: "%.\(n)d", Int(timeinterval / 3600.0))
        case let .TIMER_Total_Minutes(n):
            String(format: "%.\(n)d", Int(timeinterval / 60.0))
        case let .TIMER_Total_Seconds(n):
            String(format: "%.\(n)d", Int(timeinterval))
        case let .TIMER_Total_Milliseconds(n):
            String(format: "%.\(n)d", Int(timeinterval * 1000.0))
        }
    }

    var updatesPerSecond: Int {
        switch self {
        case .TIMER_S: 10
        case let .TIMER_Total_Milliseconds(n) where n == 1: 10
        case .TIMER_SS: 100
        case let .TIMER_Total_Milliseconds(n) where n == 2: 100
        case .TIMER_SSS: 120
        case let .TIMER_Total_Milliseconds(n) where n >= 3: 120
        default: 1
        }
    }
}

@available(iOS 15.0, *)
extension AdaptyUI.RichText {
    var timerUpdatesPerSecond: Int {
        var result = 1

        for item in items {
            if case let .tag(tagValue, _) = item,
               let timerTag = AdaptyUI.TimerTag.createFromString(tagValue)
            {
                result = max(timerTag.updatesPerSecond, result)
            }
        }

        return result
    }
}

@available(iOS 15.0, *)
struct AdaptyUITimerView: View, AdaptyTagResolver {
    var timer: AdaptyUI.Timer

    init(_ timer: AdaptyUI.Timer) {
        self.timer = timer
    }

    let startTime: Date = .init()

    @State var timeLeft: TimeInterval = 0.0
    @State var text: AdaptyUI.RichText?

    func replacement(for tag: String) -> String? {
        guard let timerTag = AdaptyUI.TimerTag.createFromString(tag) else {
            return nil // TODO: support for custom tag
        }

        return timerTag.string(for: timeLeft)
    }

    private var attributedString: AttributedString {
        AttributedString(
            text?.attributedString(
                tagResolver: self,
                productInfo: nil
            ) ?? .init()
        )
    }

    var body: some View {
        Text(attributedString)
            .onAppear {
                updateTime()
                startTimer()
            }
            .onDisappear {
                stopTimer()
            }
    }

    @State private var timeCounter: Timer?
    @State private var currentTimerUpdatesPerSecond = 1 {
        didSet {
            startTimer()
        }
    }

    private func startTimer() {
        stopTimer()

        timeCounter = Timer.scheduledTimer(withTimeInterval: 0.001, repeats: true) { _ in
            updateTime()
        }
    }

    private func stopTimer() {
        timeCounter?.invalidate()
        timeCounter = nil
    }

    private func updateTime() {
        let timeElapsed = Date().timeIntervalSince1970 - startTime.timeIntervalSince1970
        var timeLeft = timer.duration - timeElapsed

        guard timeLeft >= 0 else {
            timeLeft = 0

            stopTimer()

            text = timer.format(byValue: timeLeft)
            self.timeLeft = timeLeft
            return
        }

        text = timer.format(byValue: timeLeft)
        currentTimerUpdatesPerSecond = text?.timerUpdatesPerSecond ?? 1

        self.timeLeft = timeLeft
    }
}

#if DEBUG

@available(iOS 15.0, *)
extension AdaptyUI.RichText {
    static var fullTimerFormat: Self {
        .create(items: [
            .tag("TIMER_hh", .create(font: .default)),
            .text(":", .create(font: .default)),
            .tag("TIMER_mm", .create(font: .default)),
            .text(":", .create(font: .default)),
            .tag("TIMER_ss", .create(font: .default)),
        ])
    }

    static var fullTimerFormatMS: Self {
        .create(items: [
            .tag("TIMER_mm", .create(font: .default)),
            .text(":", .create(font: .default)),
            .tag("TIMER_ss", .create(font: .default)),
            .text(".", .create(font: .default)),
            .tag("TIMER_SS", .create(font: .default)),
            .text(" = ", .create(font: .default)),
            .tag("TIMER_Total_Milliseconds_6", .create(font: .default)),
        ])
    }
}

@available(iOS 15.0, *)
#Preview {
    AdaptyUITimerView(
        .create(
            id: "Preview",
            duration: 15,
            startBehaviour: .everyAppear,
            format: [
                .create(from: 10.0, value: .fullTimerFormat),
                .create(from: 8.0, value: .fullTimerFormatMS),
            ]
        )
    )
    .environmentObject(AdaptyProductsViewModel(logId: "Preview"))
    .environmentObject(AdaptyUIActionsViewModel(logId: "Preview"))
    .environmentObject(AdaptySectionsViewModel(logId: "Preview"))
    .environmentObject(AdaptyTagResolverViewModel(tagResolver: ["TEST_TAG": "Adapty"]))
}
#endif

#endif
