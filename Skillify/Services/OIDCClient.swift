import Foundation
import CryptoKit

// MARK: - Models
struct OIDCTokens: Codable {
    let accessToken: String
    let refreshToken: String?
    let idToken: String?
    let tokenType: String
    let expiresIn: Int?
}

struct OIDCUserInfo: Codable {
    let sub: String
    let name: String?
    let email: String?
    let email_verified: Bool?
}

// MARK: - Client
final class OIDCClient {
    enum Prompt: String {
        case none
        case login
    }

    private let issuer: URL          // например: https://auth.lovig.in/api/oidc
    private let clientId: String     // например: demo-ios
    private let redirectURI: String  // например: com.lovigin.ios.Skillify://oidc
    private let scopes: [String]

    // PKCE / state / nonce (держим на время флоу)
    private var codeVerifier: String?
    private var state: String?
    private var nonce: String?

    init(issuer: URL, clientId: String, redirectURI: String, scopes: [String]) {
        self.issuer = issuer
        self.clientId = clientId
        self.redirectURI = redirectURI
        self.scopes = scopes
    }

    // MARK: Authorize URL (supports prompt + custom screen)
    func buildAuthorizeURL(prompt: Prompt = .none) throws -> URL {
        let authEndpoint = issuer.appendingPathComponent("auth")

        // state, nonce, PKCE
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

        if prompt == .login {
            items.append(.init(name: "prompt", value: "login"))
        }

        var comps = URLComponents(url: authEndpoint, resolvingAgainstBaseURL: false)!
        comps.queryItems = items
        guard let url = comps.url else { throw URLError(.badURL) }
        return url
    }

    // MARK: Token

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

        let body = [
            "grant_type=authorization_code",
            "code=\(urlEncode(code))",
            "client_id=\(urlEncode(clientId))",
            "redirect_uri=\(urlEncode(redirectURI))",
            "code_verifier=\(urlEncode(codeVerifier))"
        ].joined(separator: "&")
        req.httpBody = body.data(using: .utf8)

        let (data, resp) = try await URLSession.shared.data(for: req)
        try ensure2xx(resp, data: data)

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

    func fetchUserInfo(accessToken: String) async throws -> OIDCUserInfo {
        // у тебя userinfo висит на /me (проксируешь на провайдера)
        let userinfo = issuer.appendingPathComponent("me")
        var req = URLRequest(url: userinfo)
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, resp) = try await URLSession.shared.data(for: req)
        try ensure2xx(resp, data: data)

        return try JSONDecoder().decode(OIDCUserInfo.self, from: data)
    }

    func clearStored() {
        codeVerifier = nil
        state = nil
        nonce = nil
    }

    // MARK: - Utils
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

    private func ensure2xx(_ resp: URLResponse, data: Data) throws {
        if let http = resp as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            let s = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "OIDC", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode): \(s)"])
        }
    }

    private func urlEncode(_ s: String) -> String {
        s.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? s
    }
}

private extension Data {
    func base64URLEncodedString() -> String {
        return self.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

extension OIDCClient {
    func refresh(using refreshToken: String) async throws -> OIDCTokens {
        let tokenEndpoint = issuer.appendingPathComponent("token")
        var req = URLRequest(url: tokenEndpoint)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let body = [
            "grant_type=refresh_token",
            "refresh_token=\(urlEncode(refreshToken))",
            "client_id=\(urlEncode(clientId))",
        ].joined(separator: "&")
        req.httpBody = body.data(using: .utf8)

        struct TokenResp: Decodable {
            let access_token: String
            let refresh_token: String?
            let id_token: String?
            let token_type: String
            let expires_in: Int?
        }
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw NSError(domain: "OIDC", code: 0, userInfo: [NSLocalizedDescriptionKey: "Refresh failed"])
        }
        let t = try JSONDecoder().decode(TokenResp.self, from: data)
        return .init(
            accessToken: t.access_token,
            refreshToken: t.refresh_token ?? refreshToken, // если не пришёл новый — оставь старый
            idToken: t.id_token,
            tokenType: t.token_type,
            expiresIn: t.expires_in
        )
    }
}
