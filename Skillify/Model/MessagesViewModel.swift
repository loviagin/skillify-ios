//
//  MessagesViewModel.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 23.12.2023.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth
import FirebaseFirestoreSwift
import AVFoundation

class MessagesViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var unread: [String] = []
    
    private var authViewModel: AuthViewModel?
    private var listener: ListenerRegistration?
    
    func loadMessages(_ authViewModel: AuthViewModel) async {
        guard let uid = Auth.auth().currentUser?.uid else {
            DispatchQueue.main.async {
                self.isLoading = false
            }
            return
        }
        self.authViewModel = authViewModel
        
        addMessageListener(userId: uid)
    }
    
    func setReadToAllMessages(_ chatId: String?, currentUserId: String) {
        guard let chatId else { return }
        
        if let chatIndex = messages.firstIndex(where: { $0.id == chatId }) {
            var messagesToUpdate = messages[chatIndex].messages

            // Обновляем статус сообщений
            for i in 0..<messagesToUpdate.count {
                if messagesToUpdate[i].status != "r" && messagesToUpdate[i].cUid != currentUserId {
                    messagesToUpdate[i].status = "r"
                }
            }

            // Обновляем Firestore
            let documentRef = Firestore.firestore().collection("messages").document(chatId)
            do {
                // Обернем массив сообщений в словарь перед кодированием
                let encodedData = try Firestore.Encoder().encode(["messages": messagesToUpdate])
                documentRef.updateData(encodedData) { error in
                    if let error = error {
                        print("Failed to update messages: \(error)")
                    } else {
                        print("Messages successfully updated!")
                    }
                }
            } catch {
                print("Failed to encode messages: \(error)")
            }
        }
    }
    
    func sendSupportMessage(id: String?, chat: Chat, user: User, message: Message?) {
        let text = chat.text ?? "🏞️ attachment"
        playSendSound()
        
        if let message {
            print("send message")
            try? Firestore.firestore().collection("messages").document(message.id).setData(from: message) { error in
                if let error {
                    print("Error in message creation \(error)")
                } else {
                    self.sendToSupport(id: message.id, userName: user.first_name, text: text)
                    print("sent")
                }
            }
        } else if let id { // если чат не новый 
            Firestore.firestore()
                .collection("messages")
                .document(id)
                .updateData([
                    "messages": FieldValue.arrayUnion([try! Firestore.Encoder().encode(chat)]),
                    "last": try! Firestore.Encoder().encode(LastData(userId: user.id, status: "u", text: text)),
                    "date": Date()
                ])
            { error in
                if let error {
                    print("Error in message \(error)")
                } else {
                    self.sendToSupport(id: id, userName: user.first_name, text: text)
                }
            }
        }
    }
    
    func sendMessage(id: String?, chat: Chat, cUser: User, receiverUser: User, message: Message?) {
        let text = chat.text ?? "🏞️ attachment"
        playSendSound()
        
//        if let message {
//            print("send message")
//            try? Firestore.firestore().collection("messages").document(message.id).setData(from: message) { error in
//                if let error {
//                    print("Error in message creation \(error)")
//                } else {
//                    self.sendToSupport(id: message.id, userName: user.first_name, text: text)
//                    print("sent")
//                }
//            }
//        } else if let id { // если чат не новый 
//            Firestore.firestore()
//                .collection("messages")
//                .document(id)
//                .updateData([
//                    "messages": FieldValue.arrayUnion([try! Firestore.Encoder().encode(chat)]),
//                    "last": try! Firestore.Encoder().encode(LastData(userId: user.id, status: "u", text: text)),
//                    "date": Date()
//                ])
//            { error in
//                if let error {
//                    print("Error in message \(error)")
//                } else {
//                    self.sendToSupport(id: id, userName: user.first_name, text: text)
//                }
//            }
//        }
    }
    
    private func sendToSupport(id: String, userName: String, text: String) {
//        Task {
//            await sendSupportNotification(chatId: id, text: "New message to Support. \(userName) writes: \(text)")
//        }
    }
    
    func addMessageListener(userId: String) {
        if listener == nil {
            DispatchQueue.main.async {
                self.isLoading = true
            }
            
            listener = Firestore.firestore().collection("messages")
                .addSnapshotListener(includeMetadataChanges: true) { snap, error in
                    if let error = error {
                        print(error)
                    } else if let snap = snap {
                        snap.documentChanges.forEach { diff in
                            if (diff.type == .added) {
                                if let item = try? diff.document.data(as: Message.self), self.isOurMessage(item: item) {
                                    self.messages.append(item)
                                    print("new message added \(item.id)")
                                }
                            }
                            if (diff.type == .modified) {
                                if let item = try? diff.document.data(as: Message.self), self.isOurMessage(item: item) {
                                    if let index = self.messages.firstIndex(where: { $0.id == item.id }) {
                                        self.messages[index] = item
                                        print("edited chat \(item.id)")
                                    }
                                }
                            }
                            if (diff.type == .removed) {
                                if let item = try? diff.document.data(as: Message.self) {
                                    if let index = self.messages.firstIndex(where: { $0.id == item.id }) {
                                        self.messages.remove(at: index)
                                        print("message removed \(item.id)")
                                    }
                                }
                            }
                        }
                        
                        // Сортируем сообщения после всех изменений
                        self.messages = self.messages.sorted(by: { m1, m2 in
                            if let time = m1.time, let time2 = m2.time {
                                return time > time2
                            } else if let date = m1.date, let date2 = m2.date {
                                return date > date2
                            }
                            return false
                        })
                    }
                    
                    DispatchQueue.main.async {
                        self.isLoading = false
                    }
                }
        }
    }
    
    private func isOurMessage(item: Message) -> Bool {
        if let members = item.members, members.contains(where: { $0.userId == self.authViewModel?.currentUser?.id ?? "" }) {
            return true
        } else if let members = item.uids, members.contains(where: { $0 == (self.authViewModel?.currentUser?.id ?? "") }) {
            return true
        } else {
            return false
        }
    }
    
    func getMessageId(cUid: String, userId: String) -> String? {
        return messages.first { message in
            if let members = message.members {
                let userIds = members.map { $0.userId }
                return userIds.contains(userId) && userIds.contains(cUid)
            } else if let uids = message.uids {
                return uids.contains(userId) && uids.contains(cUid)
            }
            return false
        }?.id
    }
    
    func getUserByUserId(userId: String, completion: @escaping (User?) -> Void) {
        Firestore.firestore().collection("users").document(userId).getDocument { snap, error in
            if let error {
                print(error)
                completion(nil)
            } else {
                if let user = try? snap?.data(as: User.self) {
                    completion(user)
                } else {
                    completion(nil)
                }
            }
        }
    }
    
    func getUserByMessageId(id chatId: String, completion: @escaping (User?) -> Void) {
        if let message = messages.first(where: { $0.id == chatId }) {
            var id: String {
                if let members = message.members, let cUsr = members.first(
                    where: { $0.userId != (Auth.auth().currentUser?.uid ?? "") }) {
                    return cUsr.userId
                } else if let uids = message.uids, let cUsr = uids.first(where: { $0 != (Auth.auth().currentUser?.uid ?? "") }) {
                    return cUsr
                } else {
                    return "User"
                }
            }
            
            Firestore.firestore().collection("users").document(id).getDocument { snap, error in
                if let error {
                    print(error)
                    completion(nil)
                } else {
                    if let user = try? snap?.data(as: User.self) {
                        completion(user)
                    } else {
                        completion(nil)
                    }
                }
            }
        }
    }
    
    func checkUnreadMessages(for message: Message) {
        if let last = message.last {
            if last.userId != (authViewModel?.currentUser?.id ?? "") && last.status == "u" {
                unread.append(message.id)
                unread.append(message.id)
                print("\(unread)")
            }
        }
    }
    
    private func sendSupportNotification(chatId: String, text: String) async {
        let parameters = [
            "contents": ["en": text],
            "app_id": "8c7d91d2-8a8d-43c8-945e-649cac38f30b",
            "include_external_user_ids": ["Support"],
            "data": [
                "chatId": chatId
            ]
        ] as [String : Any?]
        
        let postData = try! JSONSerialization.data(withJSONObject: parameters, options: [])
        
        let url = URL(string: "https://api.onesignal.com/notifications")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 10
        request.allHTTPHeaderFields = [
            "accept": "application/json",
            "Authorization": "Basic YzA2ZGI5MWUtYmZjZS00Y2ViLThiODItMTY5ODFjNzEwY2Zj",
            "content-type": "application/json"
        ]
        request.httpBody = postData
        
        let (data, _) = try! await URLSession.shared.data(for: request)
        print(String(decoding: data, as: UTF8.self))
    }
    
//    private func convertLastToDictionary(_ data: LastData) -> [String: Any]? {
//        do {
//            let data = try JSONEncoder().encode(data)
//            let json = try JSONSerialization.jsonObject(with: data, options: [])
//            return json as? [String: Any]
//        } catch {
//            print("Error converting chat to dictionary: \(error)")
//            return nil
//        }
//    }
    
    private func playSendSound() {
        AudioServicesPlaySystemSound(1004) // ID звука отправки SMS
    }
}

extension MessagesViewModel {
    static var mock: MessagesViewModel {
        let viewModel = MessagesViewModel()
        viewModel.messages.append(Message(id: "Support", messages: [
            Chat(cUid: "h3jcyd6EZSW1wpNbkvHwMxEdJgB2", text: "Hi", status: "u", type: .text),
            Chat(cUid: "h3jcyd6EZSW1wpNbkvHwMxEdJgB2", text: "Hi", status: "u", type: .text),
            Chat(cUid: "Support", text: "Hi222", status: "u", type: .text),
            Chat(cUid: "h3jcyd6EZSW1wpNbkvHwMxEdJgB2", text: "Hi", status: "u", type: .text),
            Chat(cUid: "h3jcyd6EZSW1wpNbkvHwMxEdJgB2", text: "Hijdncievieuhvuihviesdnvij sd nieajnvij", status: "u", type: .text),
            Chat(cUid: "h3jcyd6EZSW1wpNbkvHwMxEdJgB2", text: "Hijdncievieuhvuihviesdnvij sd nieajnvijveojvjnijvnkn  kvdjkvnk jnks ckjn is dj iuhfufhcu huhvurh ubh uhvihiuhiu  heiruhieuhviuhiushehh udhusd", status: "u", type: .text),
            Chat(cUid: "h3jcyd6EZSW1wpNbkvHwMxEdJgB2", text: "Hi", status: "u", type: .text)
        ], type: .personal))
        return viewModel
    }
}

//extension Firestore {
//    func arrayUnion<T: Encodable>(_ value: T) throws -> FieldValue {
//        let encoded = try Firestore.Encoder().encode(value)
//        return FieldValue.arrayUnion([encoded])
//    }
//}
