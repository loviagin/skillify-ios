//
//  UserViewModel.swift
//  Skillify
//
//  Created by Ilia Loviagin on 11/16/24.
//

import Foundation
import FirebaseFirestore

class UserViewModel: ObservableObject {
    @Published var profileUser: User? = nil
    private let db = Firestore.firestore()

    func loadUser(byNickname nickname: String) {
        db.collection("users").whereField("nickname", isEqualTo: nickname).getDocuments { [weak self] snapshot, error in
            if let document = snapshot?.documents.first {
                self?.profileUser = try? document.data(as: User.self)
            }
        }
    }
    
    func loadUser(byId id: String) {
        db.collection("users").document(id).getDocument { [weak self] snapshot, error in
            if let document = snapshot, document.exists {
                self?.profileUser = try? document.data(as: User.self)
            }
        }
    }
}
