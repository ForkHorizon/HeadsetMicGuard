//
//  AudioInputDevice.swift
//  HeadsetMicGuard
//
//  Created by Kiryl Shcherba on 21/05/2026.
//

import CoreAudio
import Foundation

struct AudioInputDevice: Identifiable, Equatable {
    let audioObjectID: AudioDeviceID
    let uid: String
    let name: String
    let transportType: UInt32
    let inputChannelCount: UInt32

    var id: String { uid }

    var isBuiltIn: Bool {
        transportType == kAudioDeviceTransportTypeBuiltIn
    }

    var transportName: String {
        switch transportType {
        case kAudioDeviceTransportTypeBuiltIn:
            return "Built-in"
        case kAudioDeviceTransportTypeBluetooth:
            return "Bluetooth"
        case kAudioDeviceTransportTypeBluetoothLE:
            return "Bluetooth LE"
        case kAudioDeviceTransportTypeUSB:
            return "USB"
        case kAudioDeviceTransportTypeVirtual:
            return "Virtual"
        case kAudioDeviceTransportTypeAggregate:
            return "Aggregate"
        default:
            return "Other"
        }
    }

    var menuTitle: String {
        "\(name) (\(transportName))"
    }
}
