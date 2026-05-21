//
//  AudioInputGuard.swift
//  HeadsetMicGuard
//
//  Created by Kiryl Shcherba on 21/05/2026.
//

import AppKit
import Combine
import CoreAudio
import Foundation
import ServiceManagement

final class AudioInputGuard: ObservableObject {
    @Published private(set) var inputDevices: [AudioInputDevice] = []
    @Published private(set) var currentInputDevice: AudioInputDevice?
    @Published private(set) var launchAtLoginEnabled = false
    @Published private var audioOperationError: String?
    @Published private var listenerSetupError: String?
    @Published private var launchAtLoginError: String?

    @Published var preferredInputDeviceUID: String? {
        didSet {
            if let preferredInputDeviceUID {
                userDefaults.set(preferredInputDeviceUID, forKey: DefaultsKey.preferredInputDeviceUID)
            } else {
                userDefaults.removeObject(forKey: DefaultsKey.preferredInputDeviceUID)
            }
        }
    }

    @Published var preferredInputDeviceName: String? {
        didSet {
            if let preferredInputDeviceName {
                userDefaults.set(preferredInputDeviceName, forKey: DefaultsKey.preferredInputDeviceName)
            } else {
                userDefaults.removeObject(forKey: DefaultsKey.preferredInputDeviceName)
            }
        }
    }

    @Published var isGuardEnabled: Bool {
        didSet {
            userDefaults.set(isGuardEnabled, forKey: DefaultsKey.isGuardEnabled)
            if isGuardEnabled {
                scheduleEnforcement()
            }
        }
    }

    private enum DefaultsKey {
        static let preferredInputDeviceUID = "preferredInputDeviceUID"
        static let preferredInputDeviceName = "preferredInputDeviceName"
        static let isGuardEnabled = "isGuardEnabled"
    }

    private let userDefaults: UserDefaults
    private let audioService = CoreAudioInputService()
    private let listenerQueue = DispatchQueue(label: "com.ForkHorizon.HeadsetMicGuard.coreaudio-listeners")
    private var defaultInputListener: AudioObjectPropertyListenerBlock?
    private var deviceListListener: AudioObjectPropertyListenerBlock?
    private var enforcementWorkItem: DispatchWorkItem?

    init(userDefaults: UserDefaults = .standard, startListeners: Bool = true) {
        self.userDefaults = userDefaults
        preferredInputDeviceUID = userDefaults.string(forKey: DefaultsKey.preferredInputDeviceUID)
        preferredInputDeviceName = userDefaults.string(forKey: DefaultsKey.preferredInputDeviceName)

        if userDefaults.object(forKey: DefaultsKey.isGuardEnabled) == nil {
            isGuardEnabled = true
        } else {
            isGuardEnabled = userDefaults.bool(forKey: DefaultsKey.isGuardEnabled)
        }

        refreshLaunchAtLoginState()
        refreshAudioState()

        if startListeners {
            startCoreAudioListeners()
            scheduleEnforcement()
        }
    }

    deinit {
        stopCoreAudioListeners()
    }

    var preferredInputDevice: AudioInputDevice? {
        guard let preferredInputDeviceUID else {
            return nil
        }

        return inputDevices.first { $0.uid == preferredInputDeviceUID }
    }

    var targetInputDevice: AudioInputDevice? {
        preferredInputDevice ?? builtInInputDevice
    }

    var currentInputTitle: String? {
        currentInputDevice?.menuTitle
    }

    var preferredInputTitle: String? {
        if let preferredInputDevice {
            return preferredInputDevice.menuTitle
        }

        if let preferredInputDeviceName {
            return "\(preferredInputDeviceName) (Unavailable)"
        }

        return targetInputDevice?.menuTitle
    }

    var canForcePreferredInput: Bool {
        targetInputDevice != nil
    }

    var lastError: String? {
        listenerSetupError ?? audioOperationError ?? launchAtLoginError
    }

    var statusTitle: String {
        if let lastError, !lastError.isEmpty {
            return "Needs Attention"
        }

        guard isGuardEnabled else {
            return "Paused"
        }

        guard targetInputDevice != nil else {
            return "No Input Device"
        }

        if preferredInputDeviceUID != nil, preferredInputDevice == nil {
            return "Preferred Unavailable"
        }

        if currentInputDevice?.uid == targetInputDevice?.uid {
            return "Guarding"
        }

        return "Switching Input"
    }

    var statusSystemImage: String {
        if lastError != nil {
            return "exclamationmark.triangle.fill"
        }

        guard isGuardEnabled else {
            return "mic.slash.fill"
        }

        guard targetInputDevice != nil else {
            return "questionmark.circle.fill"
        }

        if preferredInputDeviceUID != nil, preferredInputDevice == nil {
            return "mic.badge.xmark"
        }

        if currentInputDevice?.uid == targetInputDevice?.uid {
            return "mic.fill"
        }

        return "arrow.triangle.2.circlepath"
    }

    var menuBarIcon: NSImage {
        MenuBarIcon.image(for: menuBarIconState)
    }

    private var menuBarIconState: MenuBarIconState {
        if lastError != nil {
            return .attention
        }

        guard isGuardEnabled else {
            return .paused
        }

        guard targetInputDevice != nil else {
            return .unavailable
        }

        if preferredInputDeviceUID != nil, preferredInputDevice == nil {
            return .unavailable
        }

        if currentInputDevice?.uid == targetInputDevice?.uid {
            return .guarding
        }

        return .switching
    }

    func setPreferredDevice(uid: String) {
        guard let device = inputDevices.first(where: { $0.uid == uid }) else {
            return
        }

        preferredInputDeviceUID = device.uid
        preferredInputDeviceName = device.name
        forcePreferredInput()
    }

    func toggleGuardEnabled() {
        isGuardEnabled.toggle()
        refreshAudioState()
    }

    func forcePreferredInput() {
        enforcePreferredInput()
    }

    func refreshAudioStateAndEnforce() {
        refreshAudioState()
        scheduleEnforcement()
    }

    func toggleLaunchAtLogin() {
        do {
            refreshLaunchAtLoginState()

            if launchAtLoginEnabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }

            refreshLaunchAtLoginState()
            launchAtLoginError = nil
        } catch {
            launchAtLoginError = error.localizedDescription
            refreshLaunchAtLoginState()
        }
    }

    private var builtInInputDevice: AudioInputDevice? {
        inputDevices.first { $0.isBuiltIn } ?? inputDevices.first
    }

    private func refreshLaunchAtLoginState() {
        launchAtLoginEnabled = SMAppService.mainApp.status == .enabled
    }

    private func refreshAudioState() {
        do {
            let devices = try audioService.inputDevices()
            let currentInputDeviceID = try audioService.defaultInputDeviceID()

            inputDevices = devices
            currentInputDevice = devices.first { $0.audioObjectID == currentInputDeviceID }

            if preferredInputDeviceUID == nil, let defaultPreferredDevice = builtInInputDevice {
                preferredInputDeviceUID = defaultPreferredDevice.uid
                preferredInputDeviceName = defaultPreferredDevice.name
            }

            audioOperationError = nil
        } catch {
            audioOperationError = error.localizedDescription
        }
    }

    private nonisolated func scheduleRefreshAndEnforcement() {
        Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            self.refreshAudioState()
            self.scheduleEnforcement()
        }
    }

    private func scheduleEnforcement() {
        enforcementWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            self?.enforcePreferredInput()
        }

        enforcementWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(150), execute: workItem)
    }

    private func enforcePreferredInput() {
        refreshAudioState()

        guard isGuardEnabled, let targetInputDevice else {
            return
        }

        guard currentInputDevice?.uid != targetInputDevice.uid else {
            return
        }

        do {
            try audioService.setDefaultInputDeviceID(targetInputDevice.audioObjectID)
            refreshAudioState()
            audioOperationError = nil
        } catch {
            audioOperationError = error.localizedDescription
        }
    }

    private func startCoreAudioListeners() {
        guard defaultInputListener == nil, deviceListListener == nil else {
            return
        }

        let defaultInputListener: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            self?.scheduleRefreshAndEnforcement()
        }

        let deviceListListener: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            self?.scheduleRefreshAndEnforcement()
        }

        var defaultInputAddress = audioService.defaultInputDeviceAddress
        var deviceListAddress = audioService.deviceListAddress

        let defaultInputStatus = AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &defaultInputAddress,
            listenerQueue,
            defaultInputListener
        )

        let deviceListStatus = AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &deviceListAddress,
            listenerQueue,
            deviceListListener
        )

        if defaultInputStatus == noErr {
            self.defaultInputListener = defaultInputListener
        }

        if deviceListStatus == noErr {
            self.deviceListListener = deviceListListener
        }

        if defaultInputStatus == noErr && deviceListStatus == noErr {
            listenerSetupError = nil
            return
        }

        let errors = [
            defaultInputStatus == noErr ? nil : "default input listener OSStatus \(defaultInputStatus)",
            deviceListStatus == noErr ? nil : "device list listener OSStatus \(deviceListStatus)"
        ].compactMap { $0 }

        listenerSetupError = "CoreAudio listener setup failed: \(errors.joined(separator: ", "))"
    }

    private func stopCoreAudioListeners() {
        if let defaultInputListener {
            var address = audioService.defaultInputDeviceAddress
            AudioObjectRemovePropertyListenerBlock(
                AudioObjectID(kAudioObjectSystemObject),
                &address,
                listenerQueue,
                defaultInputListener
            )
        }

        if let deviceListListener {
            var address = audioService.deviceListAddress
            AudioObjectRemovePropertyListenerBlock(
                AudioObjectID(kAudioObjectSystemObject),
                &address,
                listenerQueue,
                deviceListListener
            )
        }
    }
}
