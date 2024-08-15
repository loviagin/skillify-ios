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
    @EnvironmentObject var messagesViewModel: MessagesViewModel
    
    @State private var hasLoadedMessages = false
    
    @State var profileUser: User? = nil
    @State var userId: MessageUser?
    
    var body: some View {
        NavigationStack{
            Group {
                if authViewModel.isLoading {
                    ProgressView()
                } else if authViewModel.userSession != nil {
                    AccountView()
                } else {
                    AuthView()
                }
            }
            .onOpenURL { url in
                if let scheme = url.scheme, scheme == "skillify" {
                    let destination = url.absoluteString.split(separator: "://").last
                    
                    let dest = destination?.components(separatedBy: "/").first
                    if dest == "m", let dest = destination?.components(separatedBy: "/").last {
                        authViewModel.selectedTab = .chats
                        userId = MessageUser(id: dest)
                    } else if let _ = destination?.contains("@") {
                        print("profile")
                        loadUser(String(destination?.components(separatedBy: "@").last ?? ""))
                    }
                }
            }
            .navigationDestination(item: $profileUser) { user in
                ProfileView(user: user)
            }
            .navigationDestination(item: $userId) { user in
                NewChatView(userId: user.id)
            }
        }
        .onAppear {
            //                        do {
            //                try Auth.auth().signOut()
            //                DispatchQueue.main.async {
            //                    authViewModel.userSession = nil
            //                }
            //            } catch let signOutError as NSError {
            //                print("Error signing out: %@", signOutError)
            //            }
            loadMessagesIfNeeded()
        }
        .onChange(of: authViewModel.isLoading) { _, _ in
            loadMessagesIfNeeded()
        }
    }
    
    private func loadUser(_ user: String) {
        Firestore.firestore().collection("users")
            .whereField("nickname", isEqualTo: user)
            .getDocuments 
        { snap, error in
            if let error {
                print("error App user link")
            } else {
                self.profileUser = try? snap?.documents.first?.data(as: User.self)
            }
        }
    }
    
    private func loadMessagesIfNeeded() {
        if !authViewModel.isLoading && !hasLoadedMessages {
            Task {
                await messagesViewModel.loadMessages(authViewModel)
                hasLoadedMessages = true
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel.mock)
        .environmentObject(MessagesViewModel.mock)
        .environmentObject(CallManager.mock)
}
