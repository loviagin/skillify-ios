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

    private let client = OIDCClient(
        issuer: URL(string: "\(URLs.authUrl)/api/oidc")!,
        clientId: "learnsy-ios",
        redirectURI: "com.lovigin.ios.Skillify://oidc",
        scopes: ["openid", "profile", "email", "offline_access"]
    )

    private lazy var authManager = AuthManager(client: client)
    private var session: ASWebAuthenticationSession?
    
    // UserViewModel для управления профилем пользователя
    private(set) lazy var userViewModel: UserViewModel = UserViewModel(authManager: authManager)

    func signIn() {
        startAuthFlow()
    }

    func signOut() {
        // OIDC logout через Safari (завершает сессию, но сохраняет Google/Apple SSO)
        performOIDCLogout()
    }
    
    private func performOIDCLogout() {
        let idToken = tokens?.idToken
        let logoutURL = client.buildLogoutURL(idToken: idToken)
        
        session = ASWebAuthenticationSession(
            url: logoutURL,
            callbackURLScheme: "com.lovigin.ios.Skillify"
        ) { [weak self] callbackURL, sessionError in
            guard let self else { return }
            
            // Независимо от результата, очищаем локальные данные
            Task { @MainActor in
                self.tokens = nil
                self.userInfo = nil
                self.error = nil
                self.authManager.clear()
                self.client.clearStored()
                self.userViewModel.clear()
                self.appState = .authenticating
            }
        }
        session?.presentationContextProvider = self
        session?.prefersEphemeralWebBrowserSession = false
        _ = session?.start()
    }

    // шаг 1: авторизация OIDC
    func startAuthFlow() {
        authManager.clear()  // Очищаем старые токены перед новым входом
        error = nil
        isLoading = true
        do {
            // Используем max_age=0 для принудительной реаутентификации
            let authURL = try client.buildAuthorizeURL(maxAge: 0)

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
        guard let url = URL(string: "\(URLs.serverUrl)/v1/me/peek") else { return }

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
            print("[Auth] Peek result - exists:", exists, "profile:", p.profile != nil)
            await MainActor.run {
                if exists, p.profile == nil {
                    // Пользователь уже есть в app_users - загружаем профиль
                    print("[Auth] User exists, loading profile...")
                    self.appState = .ready
                    Task {
                        await self.userViewModel.fetchProfile()
                    }
                } else if let draft = p.profile, !exists {
                    // Нет в app_users — показать форму
                    print("[Auth] User doesn't exist, showing registration...")
                    self.appState = .needsProfile(draft)
                } else {
                    // Неопознанный ответ — считаем, что ещё нет профиля
                    print("[Auth] Unknown response, showing registration...")
                    self.appState = .needsProfile(AppUserDraft(sub: userInfo?.sub ?? "", email: userInfo?.email, name: userInfo?.name, avatarUrl: nil))
                }
            }
        } catch {
            // Если это не JSON (или не те поля) — покажем тело и не роняемся
            throw NSError(domain: "API", code: 0, userInfo: [NSLocalizedDescriptionKey: "peek decode failed"])
        }
    }

    // шаг 3: пользователь нажал «Создать профиль в приложении»
    func completeBootstrap(
        name: String?,
        username: String?,
        email: String?,
        avatarUrl: String?,
        birthDate: Date?
    ) async {
        do {
            let url = URL(string: "\(URLs.serverUrl)/v1/me/bootstrap")!
            
            // Форматируем дату
            var params: [String: Any] = [:]
            if let name = name { params["name"] = name }
            if let username = username { params["username"] = username }
            if let email = email { params["email"] = email }
            if let avatarUrl = avatarUrl { params["avatarUrl"] = avatarUrl }
            if let birthDate = birthDate {
                let formatter = ISO8601DateFormatter()
                params["birthDate"] = formatter.string(from: birthDate)
            }
            
            let body = try JSONSerialization.data(withJSONObject: params)

            // performAuthorizedRequest теперь сам проставит Content-Type при наличии body
            let (data, resp) = try await authManager.performAuthorizedRequest(url, method: "POST", body: body)
            guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                let errorBody = String(data: data, encoding: .utf8) ?? "unknown error"
                throw NSError(domain: "API", code: (resp as? HTTPURLResponse)?.statusCode ?? 0, userInfo: [
                    NSLocalizedDescriptionKey: "Bootstrap failed: \(errorBody)"
                ])
            }
            _ = data
            await MainActor.run { 
                self.appState = .ready
                // Загружаем профиль пользователя после успешной регистрации
                Task {
                    await self.userViewModel.fetchProfile()
                }
            }
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
        // Проверяем, есть ли сохраненный токен
        if authManager.bearer() != nil {
            // Оставляем .idle чтобы показать LoadingView
            Task {
                do {
                    // Пытаемся проверить профиль
                    try await self.afterOIDC_PeekAndRoute()
                } catch {
                    // Если не получилось - токен невалидный, показываем StartView
                    await MainActor.run {
                        self.appState = .authenticating
                        self.error = nil
                    }
                }
            }
        } else {
            // Нет токена - показываем StartView
            self.appState = .authenticating
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
