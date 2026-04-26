import Foundation
import Security
import os

/// Deletes every `kSecClassGenericPassword` item that belongs to one of
/// the configured services. Used at first-launch to wipe stale auth
/// state that would otherwise survive app deletion on iOS.
///
/// We delete by `kSecAttrService` rather than walking each known
/// account so we also clear keys we don't directly own (e.g. the
/// supabase-swift SDK's internal Keychain entries) — every service
/// listed below is fully owned by this app.
nonisolated final class KeychainPurger {

    private let services: [String]
    private let deleter: (CFDictionary) -> OSStatus

    init(
        services: [String],
        deleter: @escaping (CFDictionary) -> OSStatus = SecItemDelete
    ) {
        self.services = services
        self.deleter = deleter
    }

    /// Best-effort: any `errSecItemNotFound` is treated as success.
    /// Other errors are logged but don't propagate — we never want a
    /// Keychain quirk to block app launch.
    func purgeAll() {
        for service in services {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service
            ]
            let status = deleter(query as CFDictionary)
            if status != errSecSuccess && status != errSecItemNotFound {
                Log.auth.warning(
                    "First-launch Keychain purge failed for service '\(service, privacy: .public)' status=\(status, privacy: .public)"
                )
            }
        }
    }
}
