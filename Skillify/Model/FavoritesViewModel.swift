//
//  FavoritesViewModel.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 07.02.2024.
//

import Foundation
import SwiftUI
import FirebaseFirestore

class FavoritesViewModel: ObservableObject {
    var authViewModel: AuthViewModel?
    @Published var selection: FavoritesEnum = .users
    @Published var favoritesUsers: [User] = []
    @Published var favoritesUGroups: [GroupSkill] = []
    
//    init() {
//        Task {
//            await work()
//        }
//    }
    
    func work() async {
        print("Start work")
        if authViewModel!.currentUser!.favorites.isEmpty { return }
        
        var sel: String {
            switch self.selection {
            case .users:
                favoritesUsers = []
                return "user"
            case .groups:
                favoritesUGroups = []
                return "group"
            }
        }
//        print(authViewModel?.currentUser?.favorites)
        for user in authViewModel!.currentUser!.favorites.filter({$0.type == sel}) {
            print("user \(user.id)")
            if !user.id.isEmpty {
                guard let snapshot = try? await Firestore.firestore().collection("users").document(user.id).getDocument() else { return }
//                print("\(snapshot.data())")
                switch selection {
                case .users:
                    favoritesUsers.append(try! snapshot.data(as: User.self))
                case .groups:
                    favoritesUGroups.append(try! snapshot.data(as: GroupSkill.self))
                }
            } else {
                print("Empty uid or user isn't log in")
            }
        }
        
        print("End work")
    }
    
    
    enum FavoritesEnum {
        case users, groups
    }
}
