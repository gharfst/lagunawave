import AVFoundation
import CoreAudio

struct AudioInputDevice: Identifiable, Equatable {
    let id: String
    let name: String
    let uid: String?
}

final class AudioDeviceManager {
    static func listInputDevices() -> [AudioInputDevice] {
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.microphone, .external],
            mediaType: .audio,
            position: .unspecified
        )
        var devices: [AudioInputDevice] = [
            AudioInputDevice(id: "system-default", name: "System Default", uid: nil)
        ]
        devices.append(contentsOf: discovery.devices.map { device in
            AudioInputDevice(id: device.uniqueID, name: device.localizedName, uid: device.uniqueID)
        })
        return devices
    }

    static func deviceID(forUID uid: String) -> AudioDeviceID? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDeviceForUID,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var deviceID = AudioDeviceID(0)
        var dataSize = UInt32(MemoryLayout<AudioDeviceID>.size)
        var uidCF = uid as CFString
        let status = withUnsafePointer(to: &uidCF) { uidPtr in
            AudioObjectGetPropertyData(
                AudioObjectID(kAudioObjectSystemObject),
                &address,
                UInt32(MemoryLayout<CFString>.size),
                uidPtr,
                &dataSize,
                &deviceID
            )
        }

        guard status == noErr, deviceID != 0 else { return nil }
        return deviceID
    }
}
