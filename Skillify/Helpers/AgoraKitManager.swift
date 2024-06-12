//
//  AgoraKitManager.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 30.12.2023.
//

import Foundation
//import AgoraRtcKit

class AgoraKitManager: NSObject, ObservableObject/*, AgoraRtcEngineDelegate*/ {
//    var agoraKit: AgoraRtcEngineKit?
//    @Published var userJoined = false
//    
//    override init() {
//        super.init()
//        
//        self.agoraKit = AgoraRtcEngineKit.sharedEngine(withAppId: "84bc59afcd4c4de282e8b3c19c11221b", delegate: self)
//    }
//
//    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
//        print("Пользователь с UID \(uid) вышел из канала. Причина: \(reason.rawValue)")
//    }
//    
//    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
//        print("Пользователь с UID \(uid) присоединился к каналу.")
//    }
//    
//    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
//        DispatchQueue.main.async {
//            self.userJoined = true
//        }
//    }
}

//extension AgoraKitManager {
//    func joinChannel(channelId: String, token: String? = nil, completion: ((Bool) -> Void)? = nil) {
//        agoraKit?.joinChannel(byToken: token, channelId: channelId, info: nil, uid: 0) { [weak self] (channel, uid, elapsed) in
//            DispatchQueue.main.async {
//                self?.userJoined = true
//                completion?(true)
//                print("Присоединились к каналу \(channel) с UID \(uid).")
//            }
//        }
//    }
//
//    func leaveChannel() {
//        agoraKit?.leaveChannel(nil)
//        DispatchQueue.main.async { [weak self] in
//            self?.userJoined = false
//            print("Покинули канал.")
//        }
//    }
//    
//    func leaveChannel(_ completion: ((Bool) -> Void)?) {
//        agoraKit?.leaveChannel({ (stats) in
//            // Очистка ресурсов или UI обновления
//            completion?(true)
//        })
//    }
//    
//    func setupLocalAudioStream() {
//        agoraKit?.enableAudio()
//        // Дополнительная настройка аудио потока
//    }
//    
//    func disableLocalAudioStream() {
//        agoraKit?.disableAudio()
//    }
//    
//    func generateAgoraToken(uid: Int, channelName: String, completion: @escaping (String?) -> Void) {
//        let url = URL(string: "https://us-central1-skillify-loviagin.cloudfunctions.net/generateAgoraToken")
//        var request = URLRequest(url: url!)
//        request.httpMethod = "POST"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        let parameters: [String: Any] = ["uid": String(uid), "channelName": channelName]
//        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
//        
//        let task = URLSession.shared.dataTask(with: request) { data, response, error in
//            if let error = error {
//                print("Ошибка при запросе токена: \(error.localizedDescription)")
//                completion(nil)
//                return
//            }
//            
//            if let response = response as? HTTPURLResponse {
//                print("Статус ответа: \(response.statusCode)")
//                if let data = data, let responseString = String(data: data, encoding: .utf8) {
//                    print("Ответ: \(responseString)")
//                }
//            }
//            
//            guard let data = data, let response = response as? HTTPURLResponse, response.statusCode == 200 else {
//                print("Ошибка при получении данных или неверный статус ответа")
//                completion(nil)
//                return
//            }
//            
//            if let tokenDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: String],
//               let token = tokenDict["token"] {
//                print("Токен получен: \(token)")
//                completion(token)
//            } else {
//                print("Ошибка декодирования токена")
//                completion(nil)
//            }
//        }
//        
//        task.resume()
//    }
//}
//
