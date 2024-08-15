//
//  ChatViewModel.swift
//  Skillify
//
//  Created by Ilia Loviagin on 8/2/24.
//

import Foundation
import FirebaseFirestore

class ChatViewModel: ObservableObject {
    @Published var chats: [Chat] = []
    @Published var messageId = ""
    
    func setMessageId(_ id: String) {
        messageId = id
        loadChats()
    }
    
    func getUser(id: String, completion: @escaping (User?) -> Void) {
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
    
    private func loadChats() {
        Firestore.firestore().collection("messages").document(messageId).addSnapshotListener { snap, error in
            if let error {
                print(error)
            } else {
                
            }
        }
    }
}
