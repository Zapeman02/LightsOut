import Foundation
import ServiceManagement

enum LoginItem {
    static let configuredKey = "loginItemConfigured"

    static var isEnabled: Bool { SMAppService.mainApp.status == .enabled }

    static func set(_ enabled: Bool) {
        if enabled { try? SMAppService.mainApp.register() } else { try? SMAppService.mainApp.unregister() }
    }

    /// The app is invisible most of the time, so it has to start at login to be useful.
    static func enableOnFirstLaunch() {
        guard Bundle.main.bundlePath.hasPrefix("/Applications/"),
              !UserDefaults.standard.bool(forKey: configuredKey) else { return }
        set(true)
        UserDefaults.standard.set(true, forKey: configuredKey)
    }
}
