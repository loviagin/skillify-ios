//
//  FirebaseService.swift
//  Skillify
//
//  Created by Ilia Loviagin on 9/22/24.
//

import Foundation
import Firebase
import FirebaseAuth

class FirebaseService {
    static func authenticateAndFetchJwtToken() async throws -> String? {
        guard let currentUser = Auth.auth().currentUser else {
            print("Пользователь не авторизован")
            return nil
        }
        
        // Получаем Firebase ID токен
        let idToken = try await currentUser.getIDTokenResult().token
        
        // Отправляем ID токен на сервер для получения JWT
        let url = URL(string: "https://nqstx.xyz/api/auth/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = ["idToken": idToken]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Проверяем статус-код
        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            print("Неуспешный запрос. Статус: \(httpResponse.statusCode)")
            return nil
        }
        
        // Парсим JWT токен из ответа сервера
        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        return json?["token"] as? String
    }
    
    static func sendAuthorizedRequestToRegisterDevice(fcmToken: String, jwtToken: String) async throws {
        let deviceId = await UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        
        let url = URL(string: "https://nqstx.xyz/api/devices/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Добавляем JWT токен в заголовок Authorization
        request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")

        let requestBody: [String: Any] = [
            "id": deviceId,
            "name": "iOS Device",
            "fcmToken": fcmToken
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])

        let (_, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            print("Сервер вернул статус: \(httpResponse.statusCode)")
        }
    }
}
