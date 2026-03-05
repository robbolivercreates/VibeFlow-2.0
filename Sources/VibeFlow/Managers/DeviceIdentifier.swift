import Foundation
import CryptoKit
import IOKit

/// Generates a stable hardware fingerprint for trial anti-abuse.
/// Same device always produces the same ID, even across reinstalls.
struct DeviceIdentifier {

    /// SHA256 hash of hardware identifiers (serial + model)
    static var deviceId: String {
        let serial = platformSerialNumber ?? "unknown-serial"
        let model = hardwareModel ?? "unknown-model"
        let raw = "\(serial):\(model):voxaigo-device-id"
        let hash = SHA256.hash(data: Data(raw.utf8))
        return hash.map { String(format: "%02x", $0) }.joined()
    }

    // MARK: - IOKit Hardware Info

    private static var platformSerialNumber: String? {
        let service = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching("IOPlatformExpertDevice")
        )
        guard service != 0 else { return nil }
        defer { IOObjectRelease(service) }

        let key = kIOPlatformSerialNumberKey as CFString
        guard let serialRef = IORegistryEntryCreateCFProperty(service, key, kCFAllocatorDefault, 0) else {
            return nil
        }
        return serialRef.takeRetainedValue() as? String
    }

    private static var hardwareModel: String? {
        var size: Int = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        guard size > 0 else { return nil }
        var model = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &model, &size, nil, 0)
        return String(cString: model)
    }
}
