//
//  MessagesViewModel.swift
//  Skillify
//
//  Created by Ilia Loviagin on 23.12.2023.
//

import Foundation
import Combine
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseAuth
import FirebaseStorage
import AVFoundation

class MessagesViewModel: ObservableObject {
    @Published var messages: [Message] = []
    private var listener: ListenerRegistration?

    func fetchMessages(for chatId: String) {
        if listener == nil {
            let db = Firestore.firestore()
            guard let currentUserId = Auth.auth().currentUser?.uid else { return }

            listener = db.collection("chats").document(chatId).collection("messages")
                .order(by: "time", descending: false)
                .addSnapshotListener { [weak self] snapshot, error in
                    if let error = error {
                        print("Error fetching messages: \(error)")
                        return
                    }
                    
                    self?.messages = snapshot?.documents.compactMap { doc in
                        let message = try? doc.data(as: Message.self)
                        
                        // Если сообщение не прочитано и отправлено не текущим пользователем, обновляем его статус на "read"
                        if let message, message.status != "read", message.userId != currentUserId {
                            self?.markMessageAsRead(chatId: chatId, messageId: doc.documentID)
                        }
                        
                        return message
                    } ?? []
                    
                    self?.checkRead(chatId, cUid: currentUserId)
                }
        }
    }
    
    func checkRead(_ chatId: String, cUid: String) {
        Firestore.firestore().collection("chats").document(chatId).getDocument { snap, error in
            if let error {
                print(error)
            } else {
                if let doc = try? snap?.data(as: Chat.self) {
                    if doc.last.userId != cUid && doc.last.status != "read" {
                        Firestore.firestore().collection("chats").document(chatId).updateData(["last.status": "read"])
                    }
                }
            }
        }
    }
    
    func getUser(userId: String, completion: @escaping (User?) -> Void) {
        let db = Firestore.firestore()
        
        // Получаем документ чата по его ID
        db.collection("users").document(userId).getDocument { (document, error) in
            if let error {
                print(error)
                completion(nil)
                return
            }
            
            guard let document = document, document.exists else {
                completion(nil) // Если документ не найден
                return
            }
            
            if let data = try? document.data(as: User.self) {
                completion(data)
            } else {
                completion(nil)
            }
        }
    }
 
    func getUserIdByChatId(chatId: String, currentId: String, completion: @escaping (String?) -> Void) {
        let db = Firestore.firestore()
        
        // Получаем документ чата по его ID
        db.collection("chats").document(chatId).getDocument { (document, error) in
            if let error {
                print(error)
                completion(nil)
                return
            }
            
            guard let document = document, document.exists, let data = try? document.data(as: Chat.self) else {
                completion(nil) // Если документ не найден
                return
            }
            
            // Извлекаем массив пользователей
            if data.users.count == 2 {
                // Находим ID собеседника
                let companionId = data.users.first(where: { $0 != currentId })
                completion(companionId)
            } else {
                completion(nil) // Если пользователей не два или массив отсутствует
            }
        }
    }
    
    func getChatIdByUserId(userId: String, currentId: String, completion: @escaping (String?) -> Void) {
        Firestore.firestore().collection("chats")
            .whereField("users", arrayContains: currentId)
            .getDocuments { (snapshot, error) in
                if let error {
                    print(error)
                    completion(nil)
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(nil) // Если ничего не найдено
                    return
                }
                
                // Фильтруем документы на клиентской стороне
                for document in documents {
                    if let chat = try? document.data(as: Chat.self) {
                        let users = chat.users
                        
                        // Проверяем, что в массиве ровно два элемента и это именно userId и currentId
                        if users.count == 2 && Set(users) == Set([userId, currentId]) {
                            completion(chat.id)
                            return
                        }
                    }
                }
                
                completion(nil) // Если подходящий документ не найден
            }
    }
    
    // Функция для установки статуса "read" для сообщения
    private func markMessageAsRead(chatId: String, messageId: String) {
        let db = Firestore.firestore()
        let messageRef = db.collection("chats").document(chatId).collection("messages").document(messageId)
        
        messageRef.updateData(["status": "read"]) { error in
            if let error {
                print("Error updating message status: \(error)")
            }
        }
    }
    
    func deleteMessage(chatId: String, messageId: String) {
        let db = Firestore.firestore()
        
        if messages.count > 1 {
            if let index = messages.firstIndex(where: { $0.id == messageId }), messages.count == index + 1 { // if it's the last message in messages
                print("the last")
                db.collection("chats").document(chatId).updateData([
                    "last": try! Firestore.Encoder().encode(
                        LastData(text: messages[index - 1].text ?? "🏞️ attachment", userId: messages[index - 1].userId, status: messages[index - 1].status)
                    ),
                    "lastTime": messages[index - 1].time
                ])
            }
            
            db.collection("chats").document(chatId).collection("messages").document(messageId).delete { error in
                if let error {
                    print(error)
                }
            }
        } else {
            deleteChat(chatId: chatId)
        }
    }
    
    func deleteChat(chatId: String) {
        Firestore.firestore().collection("chats").document(chatId).delete { error in
            if let error {
                print(error)
            }
        }
    }
    
    func editTextMessage(chatId: String, messageId: String, newText: String) {
        let db = Firestore.firestore()
        db.collection("chats").document(chatId).collection("messages").document(messageId).updateData(["text": newText]) { error in
            if let error {
                print(error)
            }
        }
        
        if let index = messages.firstIndex(where: { $0.id == messageId }), messages.count == index + 1 { // if it's the last message in messages
            print("the last")
            db.collection("chats").document(chatId).updateData([
                "last.text": newText
            ])
        }
    }
    
    
    func addEmojiToMessage(chatId: String, messageId: String, emoji: String) {
        let db = Firestore.firestore()
        db.collection("chats").document(chatId).collection("messages").document(messageId).updateData(["emoji": emoji]) { error in
            if let error {
                print(error)
            }
        }
    }
    
    func sendMessage(chatId: String, message: Message, chat: Chat? = nil, imageData: [Data]? = nil, userName: String) {
        playSendSound()
        
        let db = Firestore.firestore()
        if let chat { // new chat
            try? db.collection("chats").document(chatId).setData(from: chat) { error in
                if let error {
                    print(error)
                } else {
                    try? db.collection("chats").document(chatId).collection("messages").document(message.id).setData(from: message) { error in
                        if let error {
                            print(error)
                        }
                    }
//                    completion(.success(()))
                }
            }
        } else {
            try? db.collection("chats").document(chatId).collection("messages").document(message.id).setData(from: message) { error in
                if let error {
                    print(error)
                } else {
                    db.collection("chats").document(chatId).updateData([
                        "last": try! Firestore.Encoder().encode(LastData(text: message.text ?? "🏞️ attachment", userId: message.userId, status: "sent")),
                        "lastTime": Timestamp()
                    ]) { error in
                        if let error {
                            print(error)
                        }
                    }
                }
            }
        }
        
        if let imageData {
            uploadImages(imageData: imageData, chatId: chatId, messageId: message.id)
        }
        
        getPlayersIds(chatId: chatId) { users in
            if let users {
                for user in users {
                    self.sendNotification(header: userName, playerId: user, messageText: message.text ?? "🏞️ attachment", targetText: "m/\(message.userId)")
                }
            }
        }
    }
    
    private func getPlayersIds(chatId: String, completion: @escaping ([String]?) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            completion(nil)
            return
        }
        
        Firestore.firestore().collection("chats").document(chatId).getDocument { snap, error in
            if let error {
                print(error)
                completion(nil)
            } else {
                if let chat = try? snap?.data(as: Chat.self) {
                    var players: [String] = []

                    for user in chat.users {
                        if user != currentUserId {
                            players.append(user)
                        }
                    }
                    
                    completion(players)
                }
            }
        }
    }
    
    private func updateFirestoreDocument(with imageUrl: String, chatId: String, messageId: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        let documentRef = db.collection("chats").document(chatId).collection("messages").document(messageId)
        
        documentRef.updateData([
            "media": FieldValue.arrayUnion([imageUrl]) // Обновляем массив URL изображений
        ]) { error in
            if let error = error {
                print("Error updating document: \(error.localizedDescription)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    private func uploadImages(imageData: [Data], chatId: String, messageId: String) {
        let group = DispatchGroup()
        
        for data in imageData {
            group.enter() // Входим в группу
            
            uploadImage(data: data) { [weak self] url in
                guard let self = self else {
                    group.leave()
                    return
                }
                
                if let imageUrl = url {
                    self.updateFirestoreDocument(with: imageUrl, chatId: chatId, messageId: messageId) { success in
                        group.leave() // Выходим из группы после завершения обновления Firestore
                    }
                } else {
                    group.leave()
                }
            }
        }
    }
    
    private func uploadImage(data: Data, completion: @escaping (String?) -> Void) {
        let storage = Storage.storage()
        let storageRef = storage.reference().child("iosUsers/\(Auth.auth().currentUser?.uid ?? "c")/\(UUID().uuidString).jpg")
        
        storageRef.putData(data, metadata: nil) { metadata, error in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                completion(nil)
            } else {
                storageRef.downloadURL { url, error in
                    if let error = error {
                        print("Error getting download URL: \(error.localizedDescription)")
                        completion(nil)
                    } else if let downloadURL = url?.absoluteString {
                        completion(downloadURL) // Возвращаем URL загруженного изображения
                    }
                }
            }
        }
    }
    
    private func sendNotification(header: String, playerId: String, messageText: String, targetText: String) {
        let headers = [
            "accept": "application/json",
            "Authorization": "Basic NjcwMjEwOWItY2ZjZS00YTY3LTgyZTUtNzkzOTQ4ZGEwNzcy",
            "content-type": "application/json"
        ]
        
        let parameters = [
            "include_external_user_ids": [playerId],
            "headings": ["en": header],
            "contents": ["en": "\(messageText)"],
            "app_id": "e57ccffe-08a9-4fa8-8a63-8c3b143d2efd",
            "url": "skillify://\(targetText)"
        ] as [String : Any]
                
        let postData = try? JSONSerialization.data(withJSONObject: parameters, options: [])
        
        let request = NSMutableURLRequest(url: NSURL(string: "https://onesignal.com/api/v1/notifications")! as URL,
                                          cachePolicy: .useProtocolCachePolicy,
                                          timeoutInterval: 10.0)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = postData! as Data
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            if (error != nil) {
                print(error as Any)
            } else {
                _ = response as? HTTPURLResponse
            }
        })
        
        dataTask.resume()
        print("sent notification")
    }
    
    private func playSendSound() {
        AudioServicesPlaySystemSound(1004) // ID звука отправки SMS
    }
    
    func detachListener() {
        listener?.remove()
    }
}
