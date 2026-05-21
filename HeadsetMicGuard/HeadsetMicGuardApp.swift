//
//  HeadsetMicGuardApp.swift
//  HeadsetMicGuard
//
//  Created by Kiryl Shcherba on 21/05/2026.
//

import SwiftUI

@main
struct HeadsetMicGuardApp: App {
    @StateObject private var guardModel = AudioInputGuard()

    var body: some Scene {
        MenuBarExtra {
            ContentView(model: guardModel)
        } label: {
            Image(nsImage: guardModel.menuBarIcon)
        }
        .menuBarExtraStyle(.menu)
    }
}
