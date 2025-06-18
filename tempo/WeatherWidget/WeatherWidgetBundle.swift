//
//  WeatherWidgetBundle.swift
//  WeatherWidget
//
//  Created by user274988 on 6/17/R7.
//

import WidgetKit
import SwiftUI

@main
struct WeatherWidgetBundle: WidgetBundle {
    var body: some Widget {
        WeatherWidget()
        WeatherWidgetControl()
        WeatherWidgetLiveActivity()
    }
}
