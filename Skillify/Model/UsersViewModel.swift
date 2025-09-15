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
    
    var currentUser: User?
    
    func loadAllUsers() {
        Task {
            await fetchAllUsers(currentUser: currentUser)
        }
    }
    
    func fetchAllUsers(currentUser: User?) async {
        let querySnapshot = try? await Firestore.firestore().collection("users").getDocuments()
        
        guard let documents = querySnapshot?.documents else {
            print("No documents")
            return
        }
        
        let allUsers = documents.compactMap { queryDocumentSnapshot -> User? in
            try? queryDocumentSnapshot.data(as: User.self)
        }
        
        DispatchQueue.main.async {
            self.users = allUsers.filter { user in
                !user.first_name.isEmpty && user.block == nil
            }
        }
        
        self.searchUsers(by: .firstName)
    }
    
    func searchUsers(by category: SearchCategory) {
        DispatchQueue.main.async {
            if self.searchText.isEmpty {
                self.filteredUsers = self.users
            } else {
                switch category {
                case .firstName:
                    self.filteredUsers = self.users.filter { $0.first_name.lowercased().contains(self.searchText.lowercased()) || $0.last_name.lowercased().contains(self.searchText.lowercased()) }
                case .skill:
                    self.filteredUsers = self.users.filter { $0.selfSkills.map({$0.name}).description.lowercased().contains(self.searchText.lowercased()) ||
                        $0.learningSkills.map({$0.name}).description.lowercased().contains(self.searchText.lowercased())}
                    //        case .group:
                    //            filteredUsers = users.filter { $0.nickname.lowercased().contains(searchText.lowercased()) }
                }
            }
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
