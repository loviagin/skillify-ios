//
//  AuthManager.swift
//  Skillify
//
//  Created by Ilia Loviagin on 9/16/25.
//

import Foundation

final class AuthManager {
    private let client: OIDCClient
    private let store = KeychainTokenStore()   // твой Keychain-стор
    private let refreshSkew: TimeInterval = 120

    init(client: OIDCClient) {
        self.client = client
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

    @discardableResult
    func refreshIfNeeded(force: Bool = false) async throws -> OIDCTokens? {
        guard let rt = store.current?.refreshToken else { return nil }
        if !force && !store.isExpiring(within: refreshSkew) { return nil }
        let newTokens = try await client.refresh(using: rt)
        store.set(tokens: newTokens)
        store.scheduleProactiveRefresh(advanceSeconds: refreshSkew) { [weak self] in
            Task { try? await self?.refreshIfNeeded(force: true) }
        }
        return newTokens
    }

    func performAuthorizedRequest(_ url: URL,
                                  method: String = "GET",
                                  body: Data? = nil) async throws -> (Data, URLResponse) {
        try await refreshIfNeeded()

        var req = URLRequest(url: url)
        req.httpMethod = method
        if let body {
            req.httpBody = body
            // Если отправляем тело — гарантируем Content-Type: application/json
            if req.value(forHTTPHeaderField: "Content-Type") == nil {
                req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
        }
        if let at = bearer() { 
            req.setValue("Bearer \(at)", forHTTPHeaderField: "Authorization") 
        }
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, http.statusCode == 401 {
            _ = try await refreshIfNeeded(force: true)
            var retry = URLRequest(url: url)
            retry.httpMethod = method
            retry.httpBody = body
            if let body, retry.value(forHTTPHeaderField: "Content-Type") == nil {
                retry.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
            if let at = bearer() { retry.setValue("Bearer \(at)", forHTTPHeaderField: "Authorization") }
            retry.setValue("application/json", forHTTPHeaderField: "Accept")
            return try await URLSession.shared.data(for: retry)
        }
        return (data, resp)
    }
}
