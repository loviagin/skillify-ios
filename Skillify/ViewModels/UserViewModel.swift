//
//  UserViewModel.swift
//  Skillify
//
//  Created by Ilia Loviagin on 10/6/25.
//

import Foundation
import UIKit

// MARK: - API Response Models
struct FollowingResponse: Codable {
    let isFollowing: Bool
}

final class UserViewModel: ObservableObject {
    @Published var currentUser: AppUser?
    @Published var isLoading = false
    @Published var error: String?
    @Published var allUsers: [AppUser] = []
    
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

    // MARK: - Fetch All Users
    @MainActor
    func fetchAllUsers() async {
        error = nil
        do {
            guard let url = URL(string: "\(URLs.serverUrl)/v1/users") else {
                throw NSError(domain: "UserViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            }

            let (data, response) = try await authManager.performAuthorizedRequest(url)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                throw NSError(domain: "UserViewModel", code: (response as? HTTPURLResponse)?.statusCode ?? -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch users"])
            }

            struct SlimSkill: Decodable {
                struct S: Decodable { let id: String; let name: String; let category: String; let icon_name: String? }
                let skill: S
                let level: String?
            }

            struct SlimUser: Decodable, Identifiable {
                let id: String
                let auth_user_id: String
                let name: String?
                let username: String?
                let email_snapshot: String?
                let avatar_url: String?
                let bio: String?
                let birth_date: String?
                let roles: [String]?
                let last_login_at: String?
                let created_at: String?
                let updated_at: String?
                let owned_skills: [SlimSkill]?
                let desired_skills: [SlimSkill]?
                let subscription: AppUser.Subscription?
            }

            let raw = try JSONDecoder().decode([SlimUser].self, from: data)

            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let isoNoMs = ISO8601DateFormatter()
            isoNoMs.formatOptions = [.withInternetDateTime]
            let ymd = DateFormatter()
            ymd.dateFormat = "yyyy-MM-dd"
            ymd.timeZone = TimeZone(secondsFromGMT: 0)

            func parseDate(_ s: String?) -> Date? {
                guard let s else { return nil }
                return iso.date(from: s) ?? isoNoMs.date(from: s) ?? ymd.date(from: s)
            }

            func mapLevel(_ s: String?) -> SkillLevel? {
                guard let s else { return nil }
                switch s.lowercased() {
                case "bronze": return .bronze
                case "silver": return .silver
                case "gold": return .gold
                default: return nil
                }
            }

            func mapSkill(_ ss: SlimSkill) -> UserSkill {
                let skill = Skill(id: ss.skill.id, name: ss.skill.name, category: ss.skill.category, iconName: ss.skill.icon_name)
                return UserSkill(skill: skill, level: mapLevel(ss.level))
            }

            let mapped = raw.map { u in
                AppUser(
                    id: u.id,
                    authUserId: u.auth_user_id,
                    emailSnapshot: u.email_snapshot,
                    name: u.name,
                    username: u.username,
                    bio: u.bio,
                    birthDate: parseDate(u.birth_date),
                    avatarUrl: u.avatar_url,
                    roles: u.roles ?? [],
                    ownedSkills: (u.owned_skills ?? []).map(mapSkill),
                    desiredSkills: (u.desired_skills ?? []).map(mapSkill),
                    lastLoginAt: parseDate(u.last_login_at),
                    createdAt: parseDate(u.created_at) ?? Date(),
                    updatedAt: parseDate(u.updated_at) ?? Date(),
                    subscription: u.subscription
                )
            }
            print("[UserViewModel] fetched users: \(mapped.count)")
            self.allUsers = mapped
        } catch {
            print("[UserViewModel] Failed to fetch users:", error)
            self.error = "Failed to load users: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Fetch Profile
    
    /// Загружает профиль пользователя по ID
    func getUserProfile(userId: String) async -> AppUser? {
        do {
            guard let url = URL(string: "\(URLs.serverUrl)/v1/users/\(userId)") else {
                print("❌ Invalid URL for user profile: \(userId)")
                return nil
            }
            
            let (data, response) = try await authManager.performAuthorizedRequest(url)
            
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                print("❌ Failed to fetch user profile: \(userId), status: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                return nil
            }
            
            let decoder = JSONDecoder()
            // Используем ту же стратегию декодирования дат, что и в fetchProfile
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)
                
                // Пробуем разные форматы дат
                let iso8601Formatter = ISO8601DateFormatter()
                iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                
                if let date = iso8601Formatter.date(from: dateString) {
                    return date
                }
                
                let iso8601NoMsFormatter = ISO8601DateFormatter()
                iso8601NoMsFormatter.formatOptions = [.withInternetDateTime]
                
                if let date = iso8601NoMsFormatter.date(from: dateString) {
                    return date
                }
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                
                if let date = dateFormatter.date(from: dateString) {
                    return date
                }
                
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
            }
            
            let user = try decoder.decode(AppUser.self, from: data)
            print("✅ Successfully fetched user profile: \(user.id) - \(user.name)")
            return user
            
        } catch {
            print("❌ Error fetching user profile: \(error)")
            return nil
        }
    }
    
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
    
    // MARK: - Subscription Methods
    func followUser(userId: String) async -> Bool {
        let urlString = "\(URLs.serverUrl)/v1/users/\(userId)/follow"
        print("🌐 Follow URL: \(urlString)")
        guard let url = URL(string: urlString) else { 
            print("❌ Invalid URL: \(urlString)")
            return false 
        }
        
        do {
            print("📡 Making POST request to follow user...")
            let (_, response) = try await authManager.performAuthorizedRequest(url, method: "POST")
            guard let httpResponse = response as? HTTPURLResponse else { 
                print("❌ Invalid HTTP response")
                return false 
            }
            print("📡 Follow response status: \(httpResponse.statusCode)")
            return httpResponse.statusCode == 200 || httpResponse.statusCode == 201
        } catch {
            print("❌ Follow error: \(error)")
            return false
        }
    }
    
    func unfollowUser(userId: String) async -> Bool {
        guard let url = URL(string: "\(URLs.serverUrl)/v1/users/\(userId)/follow") else { return false }
        
        do {
            let (_, response) = try await authManager.performAuthorizedRequest(url, method: "DELETE")
            guard let httpResponse = response as? HTTPURLResponse else { return false }
            return httpResponse.statusCode == 200
        } catch {
            print("Unfollow error: \(error)")
            return false
        }
    }
    
    func checkIfFollowing(userId: String) async -> Bool {
        guard let url = URL(string: "\(URLs.serverUrl)/v1/users/\(userId)/following") else { return false }
        
        do {
            let (data, response) = try await authManager.performAuthorizedRequest(url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return false }
            
            let result = try JSONDecoder().decode(FollowingResponse.self, from: data)
            return result.isFollowing
        } catch {
            print("Check following error: \(error)")
            return false
        }
    }
    
    func getUserSubscriptions() async -> [AppUser] {
        guard let url = URL(string: "\(URLs.serverUrl)/v1/me/subscriptions") else { return [] }
        
        do {
            let (data, response) = try await authManager.performAuthorizedRequest(url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return [] }
            
            let users = try JSONDecoder().decode([AppUser].self, from: data)
            return users
        } catch {
            print("Get subscriptions error: \(error)")
            return []
        }
    }
    
    func getUserFollowers() async -> [AppUser] {
        guard let url = URL(string: "\(URLs.serverUrl)/v1/me/followers") else { return [] }
        
        do {
            let (data, response) = try await authManager.performAuthorizedRequest(url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return [] }
            
            let users = try JSONDecoder().decode([AppUser].self, from: data)
            return users
        } catch {
            print("Get followers error: \(error)")
            return []
        }
    }
}

