//
//  ContentView.swift
//  HeadsetMicGuard
//
//  Created by Kiryl Shcherba on 21/05/2026.
//

import AppKit
import SwiftUI

struct ContentView: View {
    @ObservedObject var model: AudioInputGuard

    var body: some View {
        statusSection

        Divider()

        preferredInputSection

        Divider()

        Button {
            model.toggleGuardEnabled()
        } label: {
            Label(model.isGuardEnabled ? "Pause Guard" : "Resume Guard",
                  systemImage: model.isGuardEnabled ? "pause.fill" : "play.fill")
        }

        Button {
            model.forcePreferredInput()
        } label: {
            Label("Force Now", systemImage: "arrow.clockwise")
        }
        .disabled(!model.canForcePreferredInput)

        Divider()

        Button {
            model.toggleLaunchAtLogin()
        } label: {
            Label(model.launchAtLoginEnabled ? "Disable Launch at Login" : "Enable Launch at Login",
                  systemImage: model.launchAtLoginEnabled ? "checkmark.circle.fill" : "circle")
        }

        Divider()

        Button {
            NSApplication.shared.terminate(nil)
        } label: {
            Label("Quit HeadsetMicGuard", systemImage: "power")
        }
    }

    private var statusSection: some View {
        Section {
            Label(model.statusTitle, systemImage: model.statusSystemImage)

            if let currentInputTitle = model.currentInputTitle {
                Text("Current: \(currentInputTitle)")
            } else {
                Text("Current: Unknown")
            }

            if let preferredInputTitle = model.preferredInputTitle {
                Text("Preferred: \(preferredInputTitle)")
            }

            if let lastError = model.lastError {
                Text("Error: \(lastError)")
            }
        }
    }

    private var preferredInputSection: some View {
        Section("Preferred Microphone") {
            if model.inputDevices.isEmpty {
                Text("No input devices found")
            } else {
                ForEach(model.inputDevices) { device in
                    Button {
                        model.setPreferredDevice(uid: device.uid)
                    } label: {
                        Label(device.menuTitle,
                              systemImage: model.preferredInputDeviceUID == device.uid ? "checkmark.circle.fill" : "circle")
                    }
                }
            }

            Button {
                model.refreshAudioStateAndEnforce()
            } label: {
                Label("Refresh Devices", systemImage: "arrow.triangle.2.circlepath")
            }
        }
    }
}

#Preview {
    ContentView(
        model: AudioInputGuard(
            userDefaults: UserDefaults(suiteName: "HeadsetMicGuardPreview") ?? .standard,
            startListeners: false
        )
    )
}
