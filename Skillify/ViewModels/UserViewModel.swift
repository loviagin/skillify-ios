//
//  UserViewModel.swift
//  Skillify
//
//  Created by Ilia Loviagin on 10/6/25.
//

import Foundation
import UIKit

final class UserViewModel: ObservableObject {
    @Published var currentUser: AppUser?
    @Published var isLoading = false
    @Published var error: String?
    
    private let authManager: AuthManager
    
    init(authManager: AuthManager) {
        self.authManager = authManager
    }

    // MARK: - Username availability
    func isUsernameAvailable(_ username: String) async -> Bool {
        guard let url = URL(string: "\(URLs.serverUrl)/v1/me/username-available?username=\(username)") else { return false }
        do {
            let (data, resp) = try await authManager.performAuthorizedRequest(url)
            guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { return false }
            struct Resp: Decodable { let available: Bool? }
            let r = try JSONDecoder().decode(Resp.self, from: data)
            return r.available ?? false
        } catch { return false }
    }
    
    // MARK: - Fetch Profile
    
    /// Загружает профиль текущего пользователя
    @MainActor
    func fetchProfile() async {
        isLoading = true
        error = nil
        
        do {
            guard let url = URL(string: "\(URLs.serverUrl)/v1/me") else {
                throw NSError(domain: "UserViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            }
            
            let (data, response) = try await authManager.performAuthorizedRequest(url)
            
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                throw NSError(domain: "UserViewModel", code: (response as? HTTPURLResponse)?.statusCode ?? -1, userInfo: [
                    NSLocalizedDescriptionKey: "Failed to fetch profile"
                ])
            }
            
            // DEBUG: Логируем ответ
            if let responseString = String(data: data, encoding: .utf8) {
                print("[UserViewModel] Profile response:", responseString)
            }
            
            let decoder = JSONDecoder()
            // НЕ используем .convertFromSnakeCase, так как у AppUser есть явные CodingKeys
            
            // Кастомная стратегия для декодирования дат (поддерживает ISO8601 и формат YYYY-MM-DD)
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)
                
                // Пытаемся ISO8601 с временем
                let iso8601Formatter = ISO8601DateFormatter()
                iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let date = iso8601Formatter.date(from: dateString) {
                    return date
                }
                
                // Пытаемся ISO8601 без миллисекунд
                iso8601Formatter.formatOptions = [.withInternetDateTime]
                if let date = iso8601Formatter.date(from: dateString) {
                    return date
                }
                
                // Пытаемся формат даты YYYY-MM-DD (для birth_date)
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                if let date = dateFormatter.date(from: dateString) {
                    return date
                }
                
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string: \(dateString)")
            }
            
            let user = try decoder.decode(AppUser.self, from: data)
            
            print("[UserViewModel] Successfully decoded user:", user.id, user.name ?? "no name")
            
            await MainActor.run {
                self.currentUser = user
                self.isLoading = false
            }
        } catch {
            print("[UserViewModel] Failed to fetch profile:", error)
            if let decodingError = error as? DecodingError {
                print("[UserViewModel] Decoding error details:", decodingError)
            }
            await MainActor.run {
                self.error = "Failed to load profile: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Update Profile
    
    /// Обновляет профиль пользователя
    @MainActor
    func updateProfile(name: String?, avatarUrl: String?) async {
        isLoading = true
        error = nil
        
        do {
            guard let url = URL(string: "\(URLs.serverUrl)/v1/me") else {
                throw NSError(domain: "UserViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            }
            
            var params: [String: Any] = [:]
            if let name = name { params["name"] = name }
            if let avatarUrl = avatarUrl { params["avatar_url"] = avatarUrl }
            
            let body = try JSONSerialization.data(withJSONObject: params)
            
            let (data, response) = try await authManager.performAuthorizedRequest(url, method: "PUT", body: body)
            
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw NSError(domain: "UserViewModel", code: (response as? HTTPURLResponse)?.statusCode ?? -1, userInfo: [
                    NSLocalizedDescriptionKey: "Failed to update profile: \(errorBody)"
                ])
            }
            
            // Перезагружаем профиль после обновления
            await fetchProfile()
            
        } catch {
            await MainActor.run {
                self.error = "Failed to update profile: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Upload Avatar
    
    /// Загружает аватар на сервер и возвращает URL
    func uploadAvatar(_ image: UIImage) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "UserViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image"])
        }
        
        guard let url = URL(string: "\(URLs.serverUrl)/v1/me/avatar") else {
            throw NSError(domain: "UserViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        guard let accessToken = authManager.bearer() else {
            throw NSError(domain: "UserViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"avatar\"; filename=\"avatar.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "UserViewModel", code: (response as? HTTPURLResponse)?.statusCode ?? -1, userInfo: [
                NSLocalizedDescriptionKey: "Upload failed: \(errorBody)"
            ])
        }
        
        struct UploadResponse: Decodable {
            let url: String
        }
        
        let uploadResp = try JSONDecoder().decode(UploadResponse.self, from: data)
        
        // Возвращаем полный URL
        return "\(URLs.serverUrl)\(uploadResp.url)"
    }
    
    /// Обновляет аватар пользователя
    @MainActor
    func updateAvatar(_ image: UIImage) async {
        isLoading = true
        error = nil
        
        do {
            let avatarUrl = try await uploadAvatar(image)
            await updateProfile(name: currentUser?.name, avatarUrl: avatarUrl)
        } catch {
            await MainActor.run {
                self.error = "Failed to update avatar: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Clear
    
    /// Очищает данные пользователя
    @MainActor
    func clear() {
        currentUser = nil
        error = nil
        isLoading = false
    }
}

// MARK: - Mock
extension UserViewModel {
    static var mock: UserViewModel {
        let mockAuthManager = AuthManager(client: OIDCClient(
            issuer: URL(string: "https://\(URLs.authUrl)/api/oidc")!,
            clientId: "learnsy-ios",
            redirectURI: "com.lovigin.ios.Skillify://oidc",
            scopes: ["openid", "profile", "email"]
        ))
        return UserViewModel(authManager: mockAuthManager)
    }
}

