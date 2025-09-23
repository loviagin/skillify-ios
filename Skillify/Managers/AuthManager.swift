//
//  AuthManager.swift
//  Skillify
//
//  Created by Ilia Loviagin on 9/16/25.
//

import Foundation

final class AuthManager {
    private let client: OIDCClient
    private let store = TokenStore()
    private let refreshSkew: TimeInterval = 120 // 2 минуты

    init(client: OIDCClient) {
        self.client = client
        // при запуске — если есть токены, планируем обновление
        store.scheduleProactiveRefresh(advanceSeconds: refreshSkew) { [weak self] in
            Task { try? await self?.refreshIfNeeded(force: true) }
        }
    }

    func setInitialTokens(_ t: OIDCTokens) {
        store.set(tokens: t)
        store.scheduleProactiveRefresh(advanceSeconds: refreshSkew) { [weak self] in
            Task { try? await self?.refreshIfNeeded(force: true) }
        }
    }

    func clear() { store.clear() }

    func bearer() -> String? { store.current?.accessToken }

    /// Обновляет токен если он скоро истекает, либо при принудительном вызове.
    @discardableResult
    func refreshIfNeeded(force: Bool = false) async throws -> OIDCTokens? {
        guard let rt = store.current?.refreshToken else { return nil }
        if !force && !store.isExpiring(within: refreshSkew) { return nil }
        let newTokens = try await client.refresh(using: rt)
        store.set(tokens: newTokens)
        // перепланировать следующее обновление
        store.scheduleProactiveRefresh(advanceSeconds: refreshSkew) { [weak self] in
            Task { try? await self?.refreshIfNeeded(force: true) }
        }
        return newTokens
    }

    /// Выполнить запрос с автоматическим проставлением Bearer и авто-refresh при 401.
    func performAuthorizedRequest(_ url: URL,
                                  method: String = "GET",
                                  body: Data? = nil) async throws -> (Data, URLResponse) {
        // проактивный рефреш если скоро истекает
        try await refreshIfNeeded()

        var req = URLRequest(url: url)
        req.httpMethod = method
        if let body { req.httpBody = body }
        if let at = bearer() {
            req.setValue("Bearer \(at)", forHTTPHeaderField: "Authorization")
        }
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, http.statusCode == 401 {
            // пробуем раз обновить и повторить
            let _ = try await refreshIfNeeded(force: true)
            var retry = URLRequest(url: url)
            retry.httpMethod = method
            retry.httpBody = body
            if let at = bearer() {
                retry.setValue("Bearer \(at)", forHTTPHeaderField: "Authorization")
            }
            retry.setValue("application/json", forHTTPHeaderField: "Accept")
            return try await URLSession.shared.data(for: retry)
        }
        return (data, resp)
    }
}
