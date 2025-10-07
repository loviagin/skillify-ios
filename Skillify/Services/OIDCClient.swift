import Foundation
import CryptoKit

// MARK: - OIDC Client
final class OIDCClient {
    private let issuer: URL          // e.g. https://auth.lovig.in/api/oidc
    private let clientId: String     // e.g. learnsy-ios
    private let redirectURI: String  // e.g. com.lovigin.ios.Skillify://oidc
    private let scopes: [String]
    
    // PKCE / state / nonce — держим на время флоу (ВАЖНО: не терять!)
    private var codeVerifier: String?
    private var state: String?
    private var nonce: String?
    
    init(issuer: URL, clientId: String, redirectURI: String, scopes: [String]) {
        self.issuer = issuer
        self.clientId = clientId
        self.redirectURI = redirectURI
        self.scopes = scopes
    }
    
    // MARK: Authorize URL
    func buildAuthorizeURL(maxAge: Int? = nil, prompt: String? = nil) throws -> URL {
        let authEndpoint = issuer.appendingPathComponent("auth")
        let state = randomURLSafe(32)
        let nonce = randomURLSafe(32)
        let verifier = randomURLSafe(64)
        let challenge = codeChallengeS256(verifier)
        self.state = state
        self.nonce = nonce
        self.codeVerifier = verifier
        
        var items: [URLQueryItem] = [
            .init(name: "client_id", value: clientId),
            .init(name: "redirect_uri", value: redirectURI),
            .init(name: "response_type", value: "code"),
            .init(name: "scope", value: scopes.joined(separator: " ")),
            .init(name: "state", value: state),
            .init(name: "nonce", value: nonce),
            .init(name: "code_challenge", value: challenge),
            .init(name: "code_challenge_method", value: "S256"),
        ]
        
        // Добавляем max_age=0 для принудительной реаутентификации
        if let maxAge = maxAge {
            items.append(.init(name: "max_age", value: String(maxAge)))
        }
        
        // Добавляем prompt для контроля показа UI
        // prompt=select_account - показывает выбор аккаунта
        // prompt=login - показывает форму входа
        if let prompt = prompt {
            items.append(.init(name: "prompt", value: prompt))
        }
        
        var comps = URLComponents(url: authEndpoint, resolvingAgainstBaseURL: false)!
        comps.queryItems = items
        guard let url = comps.url else { throw URLError(.badURL) }
        return url
    }
    
    // MARK: Token: code → tokens
    func exchangeCodeForToken(code: String, returnedState: String) async throws -> OIDCTokens {
        guard returnedState == state else {
            throw NSError(domain: "OIDC", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid state"])
        }
        guard let codeVerifier else {
            throw NSError(domain: "OIDC", code: 400, userInfo: [NSLocalizedDescriptionKey: "Missing code_verifier"])
        }
        
        let tokenEndpoint = issuer.appendingPathComponent("token")
        var req = URLRequest(url: tokenEndpoint)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyPairs = [
            "grant_type=authorization_code",
            "code=\(urlEncode(code))",
            "client_id=\(urlEncode(clientId))",
            "redirect_uri=\(urlEncode(redirectURI))",
            "code_verifier=\(urlEncode(codeVerifier))",
        ]
        let bodyString = bodyPairs.joined(separator: "&")
        req.httpBody = bodyString.data(using: .utf8)
        
        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse {
            // Если ошибка - бросаем исключение
            if http.statusCode >= 400 {
                let bodyStr = String(data: data, encoding: .utf8) ?? "unknown error"
                throw NSError(domain: "OIDC", code: http.statusCode, userInfo: [
                    NSLocalizedDescriptionKey: "Token endpoint error: \(http.statusCode)",
                    NSLocalizedFailureReasonErrorKey: bodyStr
                ])
            }
        }
        guard !data.isEmpty else {
            throw NSError(domain: "OIDC", code: -1, userInfo: [NSLocalizedDescriptionKey: "Token endpoint returned empty body"])
        }
        
        struct TokenResp: Decodable {
            let access_token: String
            let refresh_token: String?
            let id_token: String?
            let token_type: String
            let expires_in: Int?
        }
        let t = try JSONDecoder().decode(TokenResp.self, from: data)
        
        return .init(
            accessToken: t.access_token,
            refreshToken: t.refresh_token,
            idToken: t.id_token,
            tokenType: t.token_type,
            expiresIn: t.expires_in
        )
    }
    
    // MARK: UserInfo (safe)
    func safeFetchUserInfo(accessToken: String) async throws -> OIDCUserInfo? {
        let userinfo = issuer.appendingPathComponent("me")
        var req = URLRequest(url: userinfo)
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse {
            if http.statusCode == 204 || data.isEmpty {
                return nil
            }
        }
        return try JSONDecoder().decode(OIDCUserInfo.self, from: data)
    }
    
    func clearStored() {
        codeVerifier = nil
        state = nil
        nonce = nil
    }
    
    // MARK: Logout (RP-Initiated Logout)
    func buildLogoutURL(idToken: String?) -> URL {
        let endSessionEndpoint = issuer.appendingPathComponent("session").appendingPathComponent("end")
        let postLogoutRedirect = "com.lovigin.ios.Skillify://logout"
        
        var items: [URLQueryItem] = [
            .init(name: "client_id", value: clientId),
            .init(name: "post_logout_redirect_uri", value: postLogoutRedirect),
        ]
        
        if let idToken = idToken {
            items.append(.init(name: "id_token_hint", value: idToken))
        }
        
        var comps = URLComponents(url: endSessionEndpoint, resolvingAgainstBaseURL: false)!
        comps.queryItems = items
        return comps.url ?? endSessionEndpoint
    }
    
    // MARK: Refresh
    func refresh(using refreshToken: String) async throws -> OIDCTokens {
        let tokenEndpoint = issuer.appendingPathComponent("token")
        var req = URLRequest(url: tokenEndpoint)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let bodyPairs = [
            "grant_type=refresh_token",
            "refresh_token=\(urlEncode(refreshToken))",
            "client_id=\(urlEncode(clientId))",
        ]
        req.httpBody = bodyPairs.joined(separator: "&").data(using: .utf8)
        
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw NSError(domain: "OIDC", code: 0, userInfo: [NSLocalizedDescriptionKey: "Refresh failed"])
        }
        
        struct TokenResp: Decodable {
            let access_token: String
            let refresh_token: String?
            let id_token: String?
            let token_type: String
            let expires_in: Int?
        }
        let t = try JSONDecoder().decode(TokenResp.self, from: data)
        
        return .init(
            accessToken: t.access_token,
            refreshToken: t.refresh_token ?? refreshToken,
            idToken: t.id_token,
            tokenType: t.token_type,
            expiresIn: t.expires_in
        )
    }
    
    // MARK: Utils
    private func codeChallengeS256(_ verifier: String) -> String {
        let data = Data(verifier.utf8)
        let digest = SHA256.hash(data: data)
        return Data(digest).base64URLEncodedString()
    }
    
    private func randomURLSafe(_ len: Int) -> String {
        var bytes = [UInt8](repeating: 0, count: len)
        let result = SecRandomCopyBytes(kSecRandomDefault, len, &bytes)
        if result != errSecSuccess {
            bytes = (0..<len).map { _ in UInt8.random(in: 0...255) }
        }
        return Data(bytes).base64URLEncodedString()
    }
    
    private func urlEncode(_ s: String) -> String {
        s.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? s
    }
}

private extension Data {
    func base64URLEncodedString() -> String {
        self.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
