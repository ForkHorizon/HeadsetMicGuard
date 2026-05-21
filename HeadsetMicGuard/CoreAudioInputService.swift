//
//  CoreAudioInputService.swift
//  HeadsetMicGuard
//
//  Created by Kiryl Shcherba on 21/05/2026.
//

import CoreAudio
import Foundation

struct CoreAudioError: LocalizedError {
    let operation: String
    let status: OSStatus

    var errorDescription: String? {
        "\(operation) failed with OSStatus \(status)"
    }
}

struct CoreAudioInputService {
    private let systemObjectID = AudioObjectID(kAudioObjectSystemObject)

    func inputDevices() throws -> [AudioInputDevice] {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        try check(AudioObjectGetPropertyDataSize(systemObjectID, &address, 0, nil, &dataSize),
                  operation: "Read audio device list size")

        let deviceCount = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = Array(repeating: AudioDeviceID(kAudioObjectUnknown), count: deviceCount)

        if !deviceIDs.isEmpty {
            try deviceIDs.withUnsafeMutableBufferPointer { pointer in
                guard let baseAddress = pointer.baseAddress else {
                    return
                }

                try check(AudioObjectGetPropertyData(systemObjectID, &address, 0, nil, &dataSize, baseAddress),
                          operation: "Read audio device list")
            }
        }

        return try deviceIDs.compactMap { deviceID in
            let channelCount = try inputChannelCount(for: deviceID)
            guard channelCount > 0 else {
                return nil
            }

            let uid = try stringProperty(kAudioDevicePropertyDeviceUID, for: deviceID)
            let name = (try? stringProperty(kAudioObjectPropertyName, for: deviceID)) ?? uid
            let transportType = (try? uint32Property(kAudioDevicePropertyTransportType, for: deviceID)) ?? kAudioDeviceTransportTypeUnknown

            return AudioInputDevice(
                audioObjectID: deviceID,
                uid: uid,
                name: name,
                transportType: transportType,
                inputChannelCount: channelCount
            )
        }
    }

    func defaultInputDeviceID() throws -> AudioDeviceID {
        var address = defaultInputDeviceAddress
        var deviceID = AudioDeviceID(kAudioObjectUnknown)
        var dataSize = UInt32(MemoryLayout<AudioDeviceID>.size)

        try check(AudioObjectGetPropertyData(systemObjectID, &address, 0, nil, &dataSize, &deviceID),
                  operation: "Read default input device")

        return deviceID
    }

    func setDefaultInputDeviceID(_ deviceID: AudioDeviceID) throws {
        var address = defaultInputDeviceAddress
        var mutableDeviceID = deviceID
        let dataSize = UInt32(MemoryLayout<AudioDeviceID>.size)

        try check(AudioObjectSetPropertyData(systemObjectID, &address, 0, nil, dataSize, &mutableDeviceID),
                  operation: "Set default input device")
    }

    var defaultInputDeviceAddress: AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
    }

    var deviceListAddress: AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
    }

    private func inputChannelCount(for deviceID: AudioDeviceID) throws -> UInt32 {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )

        guard AudioObjectHasProperty(deviceID, &address) else {
            return 0
        }

        var dataSize: UInt32 = 0
        try check(AudioObjectGetPropertyDataSize(deviceID, &address, 0, nil, &dataSize),
                  operation: "Read input stream configuration size")

        let rawPointer = UnsafeMutableRawPointer.allocate(
            byteCount: Int(dataSize),
            alignment: MemoryLayout<AudioBufferList>.alignment
        )
        defer { rawPointer.deallocate() }

        let audioBufferList = rawPointer.bindMemory(to: AudioBufferList.self, capacity: 1)

        try check(AudioObjectGetPropertyData(deviceID, &address, 0, nil, &dataSize, audioBufferList),
                  operation: "Read input stream configuration")

        return UnsafeMutableAudioBufferListPointer(audioBufferList)
            .reduce(UInt32(0)) { $0 + $1.mNumberChannels }
    }

    private func stringProperty(_ selector: AudioObjectPropertySelector, for objectID: AudioObjectID) throws -> String {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        guard AudioObjectHasProperty(objectID, &address) else {
            throw CoreAudioError(operation: "Read string property \(selector)", status: kAudioHardwareUnknownPropertyError)
        }

        var dataSize = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        var value: Unmanaged<CFString>?

        try check(AudioObjectGetPropertyData(objectID, &address, 0, nil, &dataSize, &value),
                  operation: "Read string property \(selector)")

        guard let value else {
            throw CoreAudioError(operation: "Read string property \(selector)", status: kAudioHardwareUnspecifiedError)
        }

        return value.takeRetainedValue() as String
    }

    private func uint32Property(_ selector: AudioObjectPropertySelector, for objectID: AudioObjectID) throws -> UInt32 {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        guard AudioObjectHasProperty(objectID, &address) else {
            throw CoreAudioError(operation: "Read UInt32 property \(selector)", status: kAudioHardwareUnknownPropertyError)
        }

        var dataSize = UInt32(MemoryLayout<UInt32>.size)
        var value = UInt32(0)

        try check(AudioObjectGetPropertyData(objectID, &address, 0, nil, &dataSize, &value),
                  operation: "Read UInt32 property \(selector)")

        return value
    }

    private func check(_ status: OSStatus, operation: String) throws {
        guard status == noErr else {
            throw CoreAudioError(operation: operation, status: status)
        }
    }
}
