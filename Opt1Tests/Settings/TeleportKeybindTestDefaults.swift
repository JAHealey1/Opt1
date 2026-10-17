import Foundation
@testable import Opt1

/// Installs an isolated `UserDefaults` suite for teleport keybind tests and
/// restores `AppSettings.defaults` when deallocated. Serialized suites share
/// a lock so parallel test bundles do not race on the seam.
enum TeleportKeybindTestDefaults {

    private static let swapLock = NSLock()

    final class Scope: @unchecked Sendable {
        private let suiteName: String
        private let isolated: UserDefaults
        private let prior: UserDefaults

        init() {
            swapLock.lock()
            suiteName = "opt1.tests.teleportLayer.\(UUID().uuidString)"
            isolated = UserDefaults(suiteName: suiteName)!
            prior = AppSettings.defaults
            AppSettings.defaults = isolated
        }

        deinit {
            AppSettings.defaults = prior
            isolated.removePersistentDomain(forName: suiteName)
            swapLock.unlock()
        }

        func revisionSnapshot() -> Int {
            AppSettings.defaults.integer(forKey: AppSettings.Keys.teleportKeybindsRevision)
        }
    }
}
