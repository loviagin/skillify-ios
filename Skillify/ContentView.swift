//
//  ContentView.swift
//  Skillify
//
//  Created by Ilia Loviagin on 5/10/24.
//

import SwiftUI
import AuthenticationServices

struct ContentView: View {
    @StateObject private var vm = AuthViewModel()

    var body: some View {
        VStack(spacing: 16) {
            Text("Skillify Auth")
                .font(.largeTitle).bold()

            if let user = vm.userInfo {
                VStack(spacing: 6) {
                    Text("Signed in").font(.headline)
                    Text("sub: \(user.sub)").font(.footnote).foregroundStyle(.secondary)
                    if let name = user.name { Text("name: \(name)").font(.footnote) }
                    if let email = user.email { Text("email: \(email)").font(.footnote) }
                }
            } else {
                Text("You are not signed in")
                    .foregroundStyle(.secondary)
            }

            Button {
                vm.signIn()
            } label: {
                Text(vm.isLoading ? "Opening…" : "Sign in")
                    .frame(maxWidth: .infinity).padding()
                    .background(Color.accentColor.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(vm.isLoading)

            if let err = vm.error {
                Text(err).font(.footnote).foregroundStyle(.red).multilineTextAlignment(.center)
            }

            if vm.tokens != nil {
                Button(role: .destructive) {
                    vm.rpLogout()
                } label: {
                    Text("Sign out")
                        .frame(maxWidth: .infinity).padding()
                        .background(Color.red.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding()
    }
}

// MARK: - ViewModel
final class AuthViewModel: NSObject, ObservableObject {
    // UI state
    @Published var isLoading = false
    @Published var error: String?
    @Published var tokens: OIDCTokens?
    @Published var userInfo: OIDCUserInfo?

    // OIDC
    private let client = OIDCClient(
        issuer: URL(string: "https://auth.lovig.in/api/oidc")!,
        clientId: "demo-ios",
        redirectURI: "com.lovigin.ios.Skillify://oidc",
        scopes: ["openid", "profile", "email", "offline_access"] // offline_access нужен для RT
    )

    private lazy var authManager = AuthManager(client: client)
    private var session: ASWebAuthenticationSession?

    // MARK: - Публичные методы для UI

    /// Одна кнопка: открывает chooser-страницу (без форса prompt/screen)
    func beginAuth() {
        startAuthFlow(prompt: .none, screen: nil, ephemeral: false)
    }

    /// Вход по email (если нужна отдельная кнопка)
    func signIn() {
        startAuthFlow(prompt: .login, screen: nil, ephemeral: false)
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
    func loadProfileFromAPI() async {
        do {
            let url = URL(string: "https://api.skillify.app/v1/me")!
            let (data, _) = try await authManager.performAuthorizedRequest(url)
            // обработай data как нужно
            print("ME:", String(data: data, encoding: .utf8) ?? "")
        } catch {
            await MainActor.run { self.error = error.localizedDescription }
        }
    }

    // MARK: - Внутреннее: запуск OIDC-потока

    /// Универсальный запуск: prompt = .none|.login; screen = "signup" как UI-хинт; ephemeral=true для чистой регистрации
    func startAuthFlow(prompt: OIDCClient.Prompt, screen: String?, ephemeral: Bool) {
        error = nil
        isLoading = true

        do {
            let authURL = try client.buildAuthorizeURL(prompt: prompt, screen: screen)
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
            session?.prefersEphemeralWebBrowserSession = ephemeral // регистрация — лучше true
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

#Preview {
    ContentView()
}
