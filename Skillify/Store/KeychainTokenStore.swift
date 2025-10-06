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
        let data = try! JSONEncoder().encode(c)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let attrs: [String: Any] = [
            kSecValueData as String: data
        ]
        let status = SecItemUpdate(query as CFDictionary, attrs as CFDictionary)
        if status == errSecItemNotFound {
            var add = query
            add[kSecValueData as String] = data
            SecItemAdd(add as CFDictionary, nil)
        }
    }

    private func load() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true
        ]
        var out: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &out)
        if status == errSecSuccess, let data = out as? Data {
            current = try? JSONDecoder().decode(Stored.self, from: data)
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
