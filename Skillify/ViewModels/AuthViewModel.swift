//
//  AuthViewModel.swift
//  Skillify
//
//  Created by Ilia Loviagin on 9/23/25.
//

import Foundation
import AuthenticationServices

final class AuthViewModel: NSObject, ObservableObject {
    // UI state
    @Published var isLoading = false
    @Published var error: String?
    @Published var tokens: OIDCTokens?
    @Published var userInfo: OIDCUserInfo?

    // OIDC
    private let client = OIDCClient(
        issuer: URL(string: "https://auth.lovig.in/api/oidc")!,
        clientId: "learnsy-ios",
        redirectURI: "com.lovigin.ios.Skillify://oidc",
        scopes: ["openid", "profile", "email", "offline_access"] // offline_access нужен для RT
    )

    private lazy var authManager = AuthManager(client: client)
    private var session: ASWebAuthenticationSession?

    // MARK: - Публичные методы для UI
    /// Вход по email (если нужна отдельная кнопка)
    func signIn() {
        startAuthFlow(prompt: .login)
    }

    func signOut() {
        tokens = nil
        userInfo = nil
        error = nil
        authManager.clear()
        client.clearStored()
        // (опц.) дернуть RP-logout провайдера через ASWebAuthenticationSession
    }

    // Пример авторизованного запроса к вашему API
//    func loadProfileFromAPI() async {
//        do {
//            let url = URL(string: "https://api.skillify.app/v1/me")!
//            let (data, _) = try await authManager.performAuthorizedRequest(url)
//            // обработай data как нужно
//            print("ME:", String(data: data, encoding: .utf8) ?? "")
//        } catch {
//            await MainActor.run { self.error = error.localizedDescription }
//        }
//    }

    // MARK: - Внутреннее: запуск OIDC-потока

    /// Универсальный запуск: prompt = .none|.login; screen = "signup" как UI-хинт; ephemeral=true для чистой регистрации
    func startAuthFlow(prompt: OIDCClient.Prompt) {
        error = nil
        isLoading = true

        do {
            let authURL = try client.buildAuthorizeURL(prompt: prompt)
            print("AUTH URL:", authURL.absoluteString)

            session = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: "com.lovigin.ios.Skillify"
            ) { [weak self] callbackURL, sessionError in
                guard let self = self else { return }
                Task { @MainActor in self.isLoading = false }

                if let sessionError {
                    Task { @MainActor in self.error = sessionError.localizedDescription }
                    return
                }
                guard let callbackURL else {
                    Task { @MainActor in self.error = "No callback URL" }
                    return
                }

                // code/state
                let comps = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)
                let code  = comps?.queryItems?.first(where: { $0.name == "code" })?.value
                let state = comps?.queryItems?.first(where: { $0.name == "state" })?.value
                let err   = comps?.queryItems?.first(where: { $0.name == "error" })?.value

                if let err {
                    Task { @MainActor in self.error = "OAuth error: \(err)" }
                    return
                }
                guard let code, let state else {
                    Task { @MainActor in self.error = "Missing code/state" }
                    return
                }

                Task {
                    do {
                        let tokens = try await self.client.exchangeCodeForToken(code: code, returnedState: state)
                        let info   = try await self.client.fetchUserInfo(accessToken: tokens.accessToken)
                        await MainActor.run {
                            self.tokens = tokens
                            self.userInfo = info
                            // ← важно: положить токены в стор и запланировать авто-refresh
                            self.authManager.setInitialTokens(tokens)
                        }
                    } catch {
                        await MainActor.run { self.error = error.localizedDescription }
                    }
                }
            }

            session?.presentationContextProvider = self
            session?.prefersEphemeralWebBrowserSession = false
            _ = session?.start()

        } catch {
            isLoading = false
            self.error = error.localizedDescription
        }
    }
    
    func rpLogout() {
        // 1) берём последний id_token, он нужен как id_token_hint
        guard let idToken = tokens?.idToken else {
            // fallback: просто чистим локально
            signOut()
            return
        }

        // 2) формируем end_session URL
        let endSession = URL(string: "https://auth.lovig.in/api/oidc/session/end")!
        let postLogoutRedirect = "https://auth.lovig.in" // должен быть в post_logout_redirect_uris у клиента
        let state = UUID().uuidString

        var comps = URLComponents(url: endSession, resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            .init(name: "id_token_hint", value: idToken),
            .init(name: "post_logout_redirect_uri", value: postLogoutRedirect),
            .init(name: "state", value: state),
        ]
        guard let url = comps.url else { return }

        // 3) открываем end_session в веб-сессии
        let sess = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: nil // здесь редирект идёт на https, схему ловить не нужно
        ) { [weak self] _, _ in
            // 4) после выхода — чистим локально
            self?.signOut()
        }
        sess.presentationContextProvider = self
        // обычная (не эпемерал) сессия — нам нужно стереть cookie на стороне провайдера
        sess.prefersEphemeralWebBrowserSession = false
        _ = sess.start()
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding
extension AuthViewModel: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}
