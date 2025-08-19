//
//  ChatViewModel.swift
//  Skillify
//
//  Created by Ilia Loviagin on 8/2/24.
//

import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

class ChatViewModel: ObservableObject {
    @Published var chats: [Chat] = []
    @Published var activeUsers: [User] = []
    @Published var unreadChats: [String: Int] = [:]
    
    private var listenerChat: ListenerRegistration?
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    init() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let uid = user?.uid {
                self?.fetchChats(for: uid)
            } else {
                self?.detachListener()
            }
        }
    }
    
    func loadActiveUsers(users: [String]) {
        if users.isEmpty {
            return
        }
        
        Firestore.firestore().collection("users").whereField("online", isEqualTo: true).whereField("id", in: users).getDocuments { snap, error in
            if let error {
                print(error)
            } else if let docs = snap?.documents, !docs.isEmpty {
                self.activeUsers.removeAll()
                for doc in docs {
                    if let user = try? doc.data(as: User.self) {
                        DispatchQueue.main.async {
                            self.activeUsers.append(user)
                        }
                    } else {
                        print("Not a valid user")
                    }
                }
            }
        }
    }
    
    func refresh() {
        if let uid = Auth.auth().currentUser?.uid, listenerChat == nil {
            fetchChats(for: uid)
        }
        
        let userId = Auth.auth().currentUser?.uid ?? ""
        let usersId: [String] = chats.flatMap { chat in
            chat.users.filter { $0 != userId }
        }
        
        loadActiveUsers(users: usersId)
    }

    func fetchChats(for userId: String) {
        let db = Firestore.firestore()
        listenerChat = db.collection("chats")
            .whereField("users", arrayContains: userId)
            .order(by: "lastTime", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Error fetching chats: \(error)")
                    return
                }
                guard let documents = snapshot?.documents else { return }
                
                self?.chats = documents.compactMap { doc in
                    try? doc.data(as: Chat.self)
                }
                
                let usersId: [String] = self?.chats.flatMap { chat in
                    chat.users.filter { $0 != userId }
                } ?? []
                
                // Обнуление предыдущих данных по непрочитанным сообщениям
                self?.unreadChats.removeAll()
                
                // Подсчет непрочитанных сообщений для каждого чата
                for doc in documents {
                    let chatId = doc.documentID
                    let messagesRef = db.collection("chats").document(chatId).collection("messages")
                    
                    messagesRef
                        .whereField("status", isEqualTo: "sent")
                        .whereField("userId", isNotEqualTo: userId) // Исключаем сообщения, отправленные текущим пользователем
                        .getDocuments { [weak self] snapshot, error in
                            if let error = error {
                                print("Error fetching unread messages: \(error)")
                                return
                            }
                            
                            let unreadCount = snapshot?.documents.count ?? 0
                            print(unreadCount)
                            // Сохраняем количество непрочитанных сообщений в unreads только если оно больше 0
                            if unreadCount > 0 {
                                self?.unreadChats[chatId] = unreadCount
                            }
                        }
                }
                
                self?.loadActiveUsers(users: usersId)
            }
    }
    
    func deleteChat(chatId: String) {
        Firestore.firestore().collection("chats").document(chatId).delete { error in
            if let error {
                print(error)
            }
        }
    }
    
    func unreadsChatCount(for chatId: String) -> Int? {
        return unreadChats[chatId]
    }
    
    func countUnread() -> Int {
        return unreadChats.values.reduce(0, +)
    }
    
    func countSupportUnread() -> Int {
        return unreadChats
            .filter { $0.key.hasPrefix("Support") }  // Фильтрация по ключам, которые начинаются с "Support"
            .values
            .reduce(0, +)  // Суммируем значения непрочитанных чатов
    }
    
//    func fetchUnreadMessagesCount(chatId: String, completion: @escaping (Result<Int, Error>) -> Void) {
//        let db = Firestore.firestore()
//        
//        db.collection("chats").document(chatId).collection("messages")
//            .whereField("status", isEqualTo: "sent")
//            .getDocuments { snapshot, error in
//                if let error = error {
//                    completion(.failure(error))
//                } else {
//                    let count = snapshot?.documents.count ?? 0
//                    completion(.success(count))
//                }
//            }
//    }
    
    func loadChatUser(chat: Chat, completion: @escaping (User?) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            completion(nil)
            return
        }
        
        guard let userId = chat.getUser(currentUserId) else {
            completion(nil)
            return
        }
        
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

    func detachListener() {
        listenerChat?.remove()
    }
}

extension ChatViewModel {
    static var mock: ChatViewModel {
        let viewModel = ChatViewModel()
        viewModel.chats.append(Chat())
        return viewModel
    }
}
