//
//  TimerCoffeeWidgetExtensionBundle.swift
//  TimerCoffeeWidgetExtension
//
//  Created by Anton Karliner on 11/02/2026.
//

import WidgetKit
import SwiftUI

@main
struct TimerCoffeeWidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        if #available(iOS 16.1, *) {
            BrewingTimerLiveActivity()
        }
    }
}
