//
//  TokenStore.swift
//  Skillify
//
//  Created by Ilia Loviagin on 9/16/25.
//

import Foundation

final class TokenStore {
    struct Stored: Codable {
        var accessToken: String
        var refreshToken: String?
        var idToken: String?
        var expiresAt: Date? // когда access_token истечёт
    }

    private let userDefaultsKey = "OIDC_TOKENS"
    private let queue = DispatchQueue(label: "auth.tokens.queue")
    private var timer: Timer?

    private(set) var current: Stored? {
        didSet { persist() }
    }

    init() {
        load()
    }

    func set(tokens: OIDCTokens) {
        let expiresAt = tokens.expiresIn.flatMap { sec in Date().addingTimeInterval(TimeInterval(sec)) }
        current = Stored(
            accessToken: tokens.accessToken,
            refreshToken: tokens.refreshToken,
            idToken: tokens.idToken,
            expiresAt: expiresAt
        )
    }

    func clear() {
        current = nil
        invalidateTimer()
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }

    private func persist() {
        guard let c = current else {
            UserDefaults.standard.removeObject(forKey: userDefaultsKey)
            return
        }
        if let data = try? JSONEncoder().encode(c) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let c = try? JSONDecoder().decode(Stored.self, from: data) {
            current = c
        }
    }

    // Планирование фонового обновления заранее (по умолчанию за 2 минуты до истечения)
    func scheduleProactiveRefresh(advanceSeconds: TimeInterval = 120,
                                  handler: @escaping () -> Void) {
        invalidateTimer()
        guard let exp = current?.expiresAt else { return }
        let fireAt = exp.addingTimeInterval(-advanceSeconds)
        if fireAt <= Date() {
            handler(); // уже скоро истекает — обновляем сразу
            return
        }
        timer = Timer(fire: fireAt, interval: 0, repeats: false) { _ in handler() }
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }

    // Утилита: истекает ли в ближайшие N секунд
    func isExpiring(within seconds: TimeInterval) -> Bool {
        guard let exp = current?.expiresAt else { return false }
        return exp.timeIntervalSinceNow <= seconds
    }
}
