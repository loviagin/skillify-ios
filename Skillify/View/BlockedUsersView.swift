//
//  BlockedUsersView.swift
//  Skillify
//
//  Created by Ilia Loviagin on 6/3/24.
//

import SwiftUI
import FirebaseFirestore

struct BlockedUsersView: View {
    @EnvironmentObject private var viewModel: AuthViewModel
    @State private var users: [User] = []
    @State var showProfile = false
    
    var body: some View {
        Group {
            if let user = viewModel.currentUser, !user.blockedUsers.isEmpty {
                List {
                    ForEach(users, id: \.self) { it in
                        NavigationLink(destination: ProfileView(/*showProfile: $showProfile, */user: it)) {
                            BlockedUserView(first_name: it.first_name, last_name: it.last_name)
                        }
                    }
                }
                .listStyle(PlainListStyle())
            } else {
                Text("No blocked users")
            }
        }
        .navigationTitle("Blocked Users")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let user = viewModel.currentUser, !user.blockedUsers.isEmpty {
                Firestore.firestore().collection("users").whereField("id", in: user.blockedUsers).getDocuments { docs, error in
                    if error != nil {
                        print("error while load blocked users")
                    } else {
                        if let docs, !docs.isEmpty {
                            users.removeAll()
                            docs.documents.forEach { item in
                                try? users.append(item.data(as: User.self))
                            }
                        }
                    }
                }
            }
        }
    }
}

struct BlockedUserView: View {
    var first_name: String
    var last_name: String
    
    var body: some View {
        Text("\(first_name) \(last_name)")
    }
}

#Preview {
    BlockedUsersView()
        .environmentObject(AuthViewModel.mock)
}
