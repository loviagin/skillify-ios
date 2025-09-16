//
//  ContentView.swift
//  Skillify
//
//  Created by Ilia Loviagin on 5/10/24.
//

import SwiftUI
//import FirebaseAuth
//import FirebaseFirestore
import AuthenticationServices

struct ContentView: View {
    @StateObject private var vm = AuthViewModel2()

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

//            Button {
//                vm.signUp()
//            } label: {
//                Text(vm.isLoading ? "Opening…" : "Create account")
//                    .frame(maxWidth: .infinity).padding()
//                    .background(Color.blue.opacity(0.12))
//                    .clipShape(RoundedRectangle(cornerRadius: 12))
//            }
//            .disabled(vm.isLoading)

            if let err = vm.error {
                Text(err).font(.footnote).foregroundStyle(.red).multilineTextAlignment(.center)
            }

            if vm.tokens != nil {
                Button(role: .destructive) {
                    vm.signOut()
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

final class AuthViewModel2: NSObject, ObservableObject {
    @Published var isLoading = false
    @Published var error: String?
    @Published var tokens: OIDCTokens?
    @Published var userInfo: OIDCUserInfo?

    // ⚠️ подставь свои значения
    private let client = OIDCClient(
        issuer: URL(string: "https://auth.lovig.in/api/oidc")!,
        clientId: "demo-ios",
        redirectURI: "com.lovigin.ios.Skillify://oidc",
        scopes: ["openid", "profile", "email", "offline_access"]
    )

    private var session: ASWebAuthenticationSession?

    func signIn()  { startAuthFlow(prompt: .none, screen: nil, ephemeral: false) }
//    func signUp()  { startAuthFlow(prompt: .none,  screen: "signup",   ephemeral: true)  }

    /// Универсальный запуск OIDC-потока
    private func startAuthFlow(prompt: OIDCClient.Prompt, screen: String?, ephemeral: Bool) {
        error = nil
        isLoading = true

        do {
            let authURL = try client.buildAuthorizeURL(prompt: prompt, screen: screen)
            print("AUTH URL:", authURL.absoluteString) // для дебага

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
                        }
                    } catch {
                        await MainActor.run { self.error = error.localizedDescription }
                    }
                }
            }

            session?.presentationContextProvider = self
            session?.prefersEphemeralWebBrowserSession = ephemeral // регистрация — только эпемерал
            _ = session?.start()

        } catch {
            isLoading = false
            self.error = error.localizedDescription
        }
    }

    func signOut() {
        tokens = nil
        userInfo = nil
        client.clearStored()
        // (опц.) можно открыть end_session_endpoint провайдера через ASWebAuthenticationSession,
        // чтобы гасить куки провайдера; тогда следующий вход/регистрация будет всегда «чистым».
    }
}

extension AuthViewModel2: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // универсальный способ получить key window
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}
//struct ContentView: View {
//    @EnvironmentObject private var authViewModel: AuthViewModel
//    @EnvironmentObject private var chatViewModel: ChatViewModel
//
//    var body: some View {
//        Group {
//            switch authViewModel.userState {
//            case .loggedOut:
//                AuthView()
//            case .loading, .loggedIn:
//                TabsView()
//            case .profileEditRequired:
//                EditProfileView()
//            case .blocked(let reason):
//                BlockedView(text: reason)
//            }
//        }
//    }
//}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel.mock)
        .environmentObject(ChatViewModel.mock)
        .environmentObject(CallManager.mock)
}
