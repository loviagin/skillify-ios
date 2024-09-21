//
//  UserHelper.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 11.02.2024.
//

import Foundation
import SwiftUI

class UserHelper {
    
    static let words = ["Swift", "Code", "Dev", "App", "Tech", "Pixel", "Data", "Cloud", "Binary", "Quantum"]
    
    static let avatars = ["avatar1", "avatar2", "avatar3", "avatar4", "avatar5", "avatar6", "avatar7", "avatar8", "avatar9", "avatar10", "avatar11", "avatar12", "avatar13", "avatar14", "avatar15", "avatar16"]
    static let covers = ["cover:1", "cover:2", "cover:3", "cover:4"]
    static let emojies = ["sunglasses", "sparkles", "flame", "fireworks", "snowflake", "bolt", "paperplane", "link", "sun.min", "moon"]
    static let statuses = ["star.fill", "moon.stars", "ellipsis.message", "phone.badge.waveform.fill", "flame.fill", "bolt.fill", "laptopcomputer", "graduationcap.fill", "beach.umbrella.fill", "cup.and.saucer.fill"]
    static let theme = ["theme1", "theme2"]

    static func isUserPro(_ date: Double?) -> Bool {
        return date ?? 0 > Date().timeIntervalSince1970
    }
    
    static func isFriends(from user: User, toUser otherUser: User) -> Bool {
        return user.subscriptions.contains(where: { $0 == otherUser.id }) && otherUser.subscriptions.contains(where: { $0 == user.id })
    }
    
    static func isMessagesBlocked(viewModel: AuthViewModel, user: User) -> String? {
        if let model = viewModel.currentUser {
            if model.blockedUsers.contains(where: { $0 == user.id }) {
                return "you blocked this user"
            } else if user.blockedUsers.contains(where: { $0 == model.id }) {
                return "you were blocked by this user"
            } else {
                return nil
            }
        }
        return nil
    }
    
    static func generateNickname() -> String {
        let firstWord = words[Int(arc4random_uniform(UInt32(words.count)))]
        let secondWord = words[Int(arc4random_uniform(UInt32(words.count)))]
        let maxNumberLength = 15 - (firstWord.count + secondWord.count)
        
        var randomNumber = ""
        if maxNumberLength > 0 {
            // Генерируем число с максимально возможным количеством цифр
            let maxNumber = Int(pow(10.0, Double(maxNumberLength))) - 1
            randomNumber = String(Int(arc4random_uniform(UInt32(maxNumber))))
        }
        
        let nickname = firstWord + secondWord + randomNumber
        
        // Убедимся, что никнейм не превышает 15 символов
        let trimmedNickname = String(nickname.prefix(15))
        
        return trimmedNickname
    }
    
    static func getStringDate() -> String {
        let currentTimeInterval = Date().timeIntervalSince1970
        let date = Date(timeIntervalSince1970: currentTimeInterval)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
    
    static func getAppVersion() -> String {
        // Получаем объект Info.plist как словарь
        if let infoDictionary = Bundle.main.infoDictionary {
            // Получаем версию приложения
            let appVersion = infoDictionary["CFBundleShortVersionString"] as? String ?? "Unknown version"
            // Получаем номер сборки
            let buildNumber = infoDictionary["CFBundleVersion"] as? String ?? "Unknown build"
            
            // Создаем и возвращаем строку с версией и номером сборки
            return "Version \(appVersion) (\(buildNumber))"
        }
        
        // В случае, если не удалось получить информацию, возвращаем индикатор неизвестности
        return "Version information not available"
    }
    
    static func getColor1(_ coverName: String) -> Color {
        switch coverName {
        case "cover:1":
            return .brandBlue.opacity(0.7)
        case "cover:2":
            return .green.opacity(0.7)
        case "cover:3":
            return .purple.opacity(0.9)
        case "cover:4":
            return .orange.opacity(0.7)
        case "cover:5":
            return .cyan.opacity(0.7)
        default:
            return .brandBlue.opacity(0.7)
        }
    }
    
    static func getColor2(_ coverName: String) -> Color {
        switch coverName {
        case "cover:1":
            return .redApp.opacity(0.7)
        case "cover:2":
            return .yellow.opacity(0.7)
        case "cover:3":
            return .pink.opacity(0.7)
        case "cover:4":
            return .blue.opacity(0.7)
        case "cover:5":
            return .purple.opacity(0.7)
        default:
            return .redApp.opacity(0.7)
        }
    }
}
