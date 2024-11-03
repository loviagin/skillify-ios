//
//  NotificationsViewModel.swift
//  Skillify
//
//  Created by Ilia Loviagin on 10/18/24.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class NotificationsViewModel: ObservableObject {
    @Published var notifications: [Notification] = []
    
    init() {
        if let uid = Auth.auth().currentUser?.uid {
            loadNotifications(for: uid)
        }
    }
    
    func loadNotifications(for uid: String) {
        Firestore.firestore()
            .collection("notifications")
            .whereField("userId", isEqualTo: uid)
            .order(by: "date", descending: true)
            .getDocuments
        { snap, error in
            if let error {
                print(error)
            } else if let docs = snap?.documents, !docs.isEmpty {
                self.notifications.removeAll()
                for doc in docs {
                    if let notification = try? doc.data(as: Notification.self) {
                        DispatchQueue.main.async {
                            self.notifications.append(notification)
                        }
                    } else {
                        print("Not a notification")
                    }
                }
            }
        }
    }
    
    func getUser(uid: String, completion: @escaping (User) -> Void) {
        Firestore.firestore().collection("users").document(uid).getDocument { snap, error in
            if let error {
                print(error)
            } else if let user = try? snap?.data(as: User.self) {
                completion(user)
            }
        }
    }
}

extension NotificationsViewModel {
    static var mock: NotificationsViewModel {
        let viewModel = NotificationsViewModel()
        viewModel.notifications.append(Notification())
        return viewModel
    }
}
