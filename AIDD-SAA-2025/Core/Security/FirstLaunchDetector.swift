import Foundation

protocol FirstLaunchDetector: AnyObject {
    /// Returns `true` on the first call after install (or reinstall),
    /// `false` on every subsequent call. Safe to call multiple times.
    func consumeFirstLaunch() -> Bool
}

/// Backed by `UserDefaults`, which iOS clears when the app is deleted.
/// That's the inverse of the Keychain's lifetime, which is what makes
/// the "delete app, reinstall, get logged out" UX possible.
nonisolated final class UserDefaultsFirstLaunchDetector: FirstLaunchDetector {

    private let storage: UserDefaults
    private let key: String

    init(
        storage: UserDefaults = .standard,
        key: String = "hasLaunchedBeforeV1"
    ) {
        self.storage = storage
        self.key = key
    }

    func consumeFirstLaunch() -> Bool {
        if storage.bool(forKey: key) { return false }
        storage.set(true, forKey: key)
        return true
    }
}
