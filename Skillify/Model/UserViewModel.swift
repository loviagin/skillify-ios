//
//  UserViewModel.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 19.12.2023.
//

import Foundation
import FirebaseFirestore

class UsersViewModel: ObservableObject {
    @Published var users = [User]()
    @Published var filteredUsers = [User]() // Отфильтрованные пользователи
    @Published var searchText = "" // Текст поиска
    
    private let db = Firestore.firestore()
    var currentUser: User?
    
//    init() {
//        fetchUsers()
//    }
    func loadUsers() {
        fetchUsers(currentUser: currentUser)
    }
    
    func loadAllUsers() {
        fetchAllUsers(currentUser: currentUser)
    }
    
    func fetchUsers(currentUser: User?) {
        db.collection("users")
            .getDocuments { [weak self] (querySnapshot, error) in
                guard let documents = querySnapshot?.documents else {
                    print("No documents: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                let allUsers = documents.compactMap { queryDocumentSnapshot -> User? in
                    try? queryDocumentSnapshot.data(as: User.self)
                }
                
                self?.users = allUsers.filter { user in
                    !user.first_name.isEmpty && user.blocked < 3 && !(currentUser?.blockedUsers.contains(user.id) ?? false)
                }
            }
    }
    
    func fetchAllUsers(currentUser: User?) {
        db.collection("users")
            .getDocuments { [weak self] (querySnapshot, error) in
                guard let documents = querySnapshot?.documents else {
                    print("No documents: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                let allUsers = documents.compactMap { queryDocumentSnapshot -> User? in
                    try? queryDocumentSnapshot.data(as: User.self)
                }
                
                self?.users = allUsers.filter { user in
                    !user.first_name.isEmpty && user.blocked < 3
                }
            }
    }
    
    func searchUsers(by category: SearchCategory) {
        switch category {
        case .firstName:
            filteredUsers = users.filter { $0.first_name.lowercased().contains(searchText.lowercased()) }
        case .skill:
            filteredUsers = users.filter { $0.selfSkills.map({$0.name}).description.lowercased().contains(searchText.lowercased()) ||
                                        $0.learningSkills.map({$0.name}).description.lowercased().contains(searchText.lowercased())}
//        case .group:
//            filteredUsers = users.filter { $0.nickname.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    enum SearchCategory: CaseIterable, Hashable {
        case firstName, skill
//        , group
        
        var tabTitle: String {
            switch self {
            case .firstName:
                return "First Name"
            case .skill:
                return "Skill"
//            case .group:
//                return "Group"
            }
        }
    }
}
