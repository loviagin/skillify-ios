//
//  ContentView.swift
//  Skillify
//
//  Created by Ilia Loviagin on 5/10/24.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
        
    @State var profileUser: User? = nil
    @State var userId: MessageUser?
    
    var body: some View {
        NavigationStack{
            Group {
                if authViewModel.isLoading {
                    ProgressView()
                } else if Auth.auth().currentUser != nil {
                    MainView()
                } else {
                    AuthView()
                }
            }
            .onOpenURL { url in
                if Auth.auth().currentUser != nil {
                    if let scheme = url.scheme, scheme == "skillify" {
                        let destination = url.absoluteString.split(separator: "://").last
                        
                        let dest = destination?.components(separatedBy: "/").first
                        if dest == "m", let dest = destination?.components(separatedBy: "/").last {
                            authViewModel.selectedTab = .chats
                            userId = MessageUser(id: dest)
                        } else if let _ = destination?.contains("@") {
                            loadUser(String(destination?.components(separatedBy: "@").last ?? ""))
                        }
                    }
                }
            }
            .navigationDestination(item: $profileUser) { user in
                ProfileView(user: user)
            }
            .navigationDestination(item: $userId) { user in
                MessagesView(userId: user.id)
            }
        }
        .onAppear {
            //                        do {
            //                try Auth.auth().signOut()
            //            } catch let signOutError as NSError {
            //                print("Error signing out: %@", signOutError)
            //            }
        }
    }
    
    private func loadUser(_ user: String) {
        Firestore.firestore().collection("users")
            .whereField("nickname", isEqualTo: user)
            .getDocuments 
        { snap, error in
            if let error {
                print(error)
            } else {
                self.profileUser = try? snap?.documents.first?.data(as: User.self)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel.mock)
        .environmentObject(ChatViewModel.mock)
        .environmentObject(CallManager.mock)
}


struct MessageUser: Identifiable, Hashable {
    var id: String = UUID().uuidString
}
