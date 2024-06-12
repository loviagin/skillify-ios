//
//  MessagesViewModel.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 23.12.2023.
//

import Foundation
import Firebase
import FirebaseFirestore

class MessagesViewModel: ObservableObject {
    @Published var messages = [Message]()
    @Published var isLoading = false
    @Published var countUnread = 0
    
    private var authViewModel: AuthViewModel?
    private var listener: ListenerRegistration?
    
    func loadMessages(_ authViewModel: AuthViewModel) async {
        print("s2")

        guard let uid = Auth.auth().currentUser?.uid else {
            DispatchQueue.main.async {
                self.isLoading = false
            }
            return
        }
        self.authViewModel = authViewModel
        
        addMessageListener(userId: uid)
    }
    
    func addMessageListener(userId: String) {
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        let messageIDs = authViewModel!.currentUser!.messages.compactMap { $0.values.first }
        fetchAndUpdateMessages(by: messageIDs)
    }
    
    func fetchAndUpdateMessages(by messageIDs: [String]) {
        guard !messageIDs.isEmpty else {
            print("Message IDs array is empty")
            return
        }
        DispatchQueue.main.async {
            self.messages.removeAll()
        }

        _ = DispatchGroup()

        for messageID in messageIDs {
            Firestore.firestore().collection("messages").document(messageID).addSnapshotListener { [weak self] (documentSnapshot, error) in

                guard let self = self else { return }
                self.countUnread = 0

                if error != nil {
                    return
                }

                guard let documentSnapshot = documentSnapshot, documentSnapshot.exists, let message = try? documentSnapshot.data(as: Message.self) else {
                    return
                }

                DispatchQueue.main.async {
                    let updatedMessage = message
//                    updatedMessage.id = documentSnapshot.documentID // Убедитесь, что ваша модель Message может обрабатывать это
                    if let index = self.messages.firstIndex(where: { $0.id == messageID }) {
                        self.messages[index] = updatedMessage
                    } else {
                        self.messages.append(updatedMessage)
                    }
//                    print("\(documentSnapshot.documentID)")
                    self.messages.sort(by: { $0.time ?? 0.0 > $1.time ?? 0.0 })
                    self.checkUnreadMessages(for: updatedMessage)
                }
            }
        }
    }
    
    func checkUnreadMessages(for message: Message) {
        // Проверяем, не пустой ли массив сообщений
        guard let messages = message.messages else { return }
        
        // Итерируемся по каждому сообщению в массиве
        for chat in messages {
            // Проверяем, равно ли поле status "u"
            if chat.cUid != authViewModel!.currentUser!.id && chat.status == "u" {
                // Если условие выполняется, увеличиваем countUnread на 1
                countUnread += 1
            }
        }
    }
}

extension MessagesViewModel {
    static var mock: MessagesViewModel {
        let viewModel = MessagesViewModel()
        return viewModel
    }
}
