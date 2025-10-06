//
//  AuthViewModel.swift
//  Skillify
//
//  Created by Ilia Loviagin on 9/23/25.
//

import Foundation
import AuthenticationServices

final class AuthViewModel: NSObject, ObservableObject {
    @Published var isLoading = false
    @Published var error: String?
    @Published var tokens: OIDCTokens?
    @Published var userInfo: OIDCUserInfo?
    @Published var appState: AppAuthState = .idle

    private let serverUrl = "https://la.nqstx.online"

    private let client = OIDCClient(
        issuer: URL(string: "https://auth.lovig.in/api/oidc")!,
        clientId: "learnsy-ios",
        redirectURI: "com.lovigin.ios.Skillify://oidc",
        scopes: ["openid", "profile", "email", "offline_access"]
    )

    private lazy var authManager = AuthManager(client: client)
    private var session: ASWebAuthenticationSession?

    func signIn() {
        startAuthFlow()
    }

    func signOut() {
        tokens = nil; userInfo = nil; error = nil
        appState = .idle
        authManager.clear()
        client.clearStored()
    }

    // шаг 1: авторизация OIDC
    func startAuthFlow() {
        authManager.clear()  // Очищаем старые токены перед новым входом
        error = nil
        isLoading = true
        do {
            let authURL = try client.buildAuthorizeURL()

            session = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: "com.lovigin.ios.Skillify"
            ) { [weak self] callbackURL, sessionError in
                guard let self else { return }
                Task { @MainActor in self.isLoading = false }

                if let sessionError {
                    Task { @MainActor in self.error = "ASWebAuth error: \(sessionError.localizedDescription)" }
                    return
                }
                guard let callbackURL else {
                    Task { @MainActor in self.error = "No callback URL" }
                    return
                }

                let comps = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)
                let code  = comps?.queryItems?.first(where: { $0.name == "code" })?.value
                let state = comps?.queryItems?.first(where: { $0.name == "state" })?.value
                let err   = comps?.queryItems?.first(where: { $0.name == "error" })?.value

                if let err {
                    Task { @MainActor in self.error = "OAuth error: \(err)" }
                    return
                }
                guard let code, let state else {
                    Task { @MainActor in self.error = "Missing code/state in callback" }
                    return
                }

                Task {
                    do {
                        let tokens = try await self.client.exchangeCodeForToken(code: code, returnedState: state)
                        let info   = try await self.client.safeFetchUserInfo(accessToken: tokens.accessToken)
                        await MainActor.run {
                            self.tokens = tokens
                            self.userInfo = info
                            self.authManager.setInitialTokens(tokens)
                        }
                        // >>> ВАЖНО: после OIDC спросить приложение и проставить appState
                        try await self.afterOIDC_PeekAndRoute()
                    } catch {
                        await MainActor.run { self.error = "After auth: \(error.localizedDescription)" }
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

    // шаг 2: спросить у app API, есть ли запись
    private func afterOIDC_PeekAndRoute() async throws {
        guard let url = URL(string: "\(serverUrl)/v1/me/peek") else { return }

        let (data, resp) = try await authManager.performAuthorizedRequest(url)
        guard let http = resp as? HTTPURLResponse else {
            throw NSError(domain: "API", code: -1, userInfo: [NSLocalizedDescriptionKey: "No HTTP response"])
        }

        // Проверим код/тип
        guard (200...299).contains(http.statusCode) else {
            throw NSError(domain: "API", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "Peek HTTP \(http.statusCode)"])
        }

        // Пытаемся распарсить JSON
        struct PeekResp: Decodable {
            let exists: Bool?
            let profile: AppUserDraft?
        }

        do {
            let p = try JSONDecoder().decode(PeekResp.self, from: data)
            let exists = p.exists ?? false
            await MainActor.run {
                if exists, p.profile == nil {
                    // Пользователь уже есть в app_users
                    self.appState = .ready
                } else if let draft = p.profile, !exists {
                    // Нет в app_users — показать форму
                    self.appState = .needsProfile(draft)
                } else {
                    // Неопознанный ответ — считаем, что ещё нет профиля
                    self.appState = .needsProfile(AppUserDraft(sub: userInfo?.sub ?? "", email: userInfo?.email, name: userInfo?.name, avatarUrl: nil))
                }
            }
        } catch {
            // Если это не JSON (или не те поля) — покажем тело и не роняемся
            throw NSError(domain: "API", code: 0, userInfo: [NSLocalizedDescriptionKey: "peek decode failed"])
        }
    }

    // шаг 3: пользователь нажал «Создать профиль в приложении»
    func completeBootstrap(name: String?, email: String?, avatarUrl: String?) async {
        do {
            let url = URL(string: "\(serverUrl)/v1/me/bootstrap")!
            let body = try JSONSerialization.data(withJSONObject: [
                "name": name as Any,
                "email": email as Any,
                "avatarUrl": avatarUrl as Any
            ].compactMapValues { $0 })

            // performAuthorizedRequest теперь сам проставит Content-Type при наличии body
            let (data, resp) = try await authManager.performAuthorizedRequest(url, method: "POST", body: body)
            guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                throw NSError(domain: "API", code: 0, userInfo: [NSLocalizedDescriptionKey: "Bootstrap failed"])
            }
            _ = data
            await MainActor.run { self.appState = .ready }
        } catch {
            await MainActor.run { self.error = error.localizedDescription }
        }
    }

    enum AppAuthState {
        case idle
        case authenticating
        case needsProfile(AppUserDraft)
        case ready
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

extension AuthViewModel {
    /// Попробовать восстановить сессию из Keychain и понять, есть ли app_user
    @MainActor
    func tryRestoreSession() {
        if authManager.bearer() != nil {
            Task {
                do {
                    try await self.afterOIDC_PeekAndRoute()
                } catch {
                    await MainActor.run {
                        self.appState = .idle
                        self.error = nil
                    }
                }
            }
        } else {
            self.appState = .idle
        }
    }

    /// Удобный вход с переключением состояния
    @MainActor
    func beginSignIn() {
        self.appState = .authenticating
        self.startAuthFlow()
    }
}

extension AuthViewModel {
    static var mock: AuthViewModel {
        let vm = AuthViewModel()
        return vm
    }
}
