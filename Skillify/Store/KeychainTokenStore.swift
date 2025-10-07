//
//  KeychainTokenStore.swift
//  Skillify
//
//  Created by Ilia Loviagin on 10/5/25.
//

import Foundation
import Security

final class KeychainTokenStore {
    struct Stored: Codable {
        var accessToken: String
        var refreshToken: String?
        var idToken: String?
        var expiresAt: Date?
    }

    private let service = "in.lovig.auth.tokens"
    private let account = "default"
    private var timer: Timer?

    private(set) var current: Stored? {
        didSet { persist() }
    }

    init() { load() }

    func set(tokens: OIDCTokens) {
        let expiresAt = tokens.expiresIn.flatMap { Date().addingTimeInterval(TimeInterval($0)) }
        current = Stored(accessToken: tokens.accessToken,
                         refreshToken: tokens.refreshToken,
                         idToken: tokens.idToken,
                         expiresAt: expiresAt)
    }

    func clear() {
        current = nil
        invalidateTimer()
        deleteFromKeychain()
    }

    func scheduleProactiveRefresh(advanceSeconds: TimeInterval = 120, handler: @escaping () -> Void) {
        invalidateTimer()
        guard let exp = current?.expiresAt else { return }
        let fireAt = exp.addingTimeInterval(-advanceSeconds)
        if fireAt <= Date() { handler(); return }
        timer = Timer(fireAt: fireAt, interval: 0, target: BlockTarget(handler), selector: #selector(BlockTarget.invoke), userInfo: nil, repeats: false)
        RunLoop.main.add(timer!, forMode: .common)
    }

    func isExpiring(within seconds: TimeInterval) -> Bool {
        guard let exp = current?.expiresAt else { return false }
        return exp.timeIntervalSinceNow <= seconds
    }

    // MARK: Keychain
    private func persist() {
        guard let c = current else { deleteFromKeychain(); return }
        do {
            let data = try JSONEncoder().encode(c)
            // Build base attributes
            var base: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account,
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            ]
            // Delete old value to avoid update edge cases on fresh devices
            SecItemDelete(base as CFDictionary)
            base[kSecValueData as String] = data
            let addStatus = SecItemAdd(base as CFDictionary, nil)
            #if DEBUG
            if addStatus != errSecSuccess {
                let code = Int(addStatus)
                print("[Keychain] SecItemAdd failed: \(code)")
            }
            #endif
        } catch {
            #if DEBUG
            print("[Keychain] Encode failed: \(error.localizedDescription)")
            #endif
        }
    }

    private func load() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: kCFBooleanTrue as Any
        ]
        var out: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &out)
        if status == errSecSuccess, let data = out as? Data {
            current = try? JSONDecoder().decode(Stored.self, from: data)
        } else {
            current = nil
        }
    }

    private func deleteFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }

    private func invalidateTimer() { timer?.invalidate(); timer = nil }
}

private final class BlockTarget {
    private let block: () -> Void
    init(_ block: @escaping () -> Void) { self.block = block }
    @objc func invoke() { block() }
}
