//
//  ContentView.swift
//  Skillify
//
//  Created by Ilia Loviagin on 5/10/24.
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var messagesViewModel: MessagesViewModel
    @EnvironmentObject var callManager: CallManager
    
    @State private var hasLoadedMessages = false
    @State private var showTopView = false

    var body: some View {
        Group {
            NavigationStack {
                if authViewModel.isLoading {
                    ProgressView()
                } else if authViewModel.userSession != nil {
                    VStack {
                        if showTopView {
                            CallTopView()
                        }
                        AccountView()
                    }
                } else {
                    AuthView()
                }
            }
        }
        .onAppear {
//            do {
//                try Auth.auth().signOut()
//                DispatchQueue.main.async {
//                    authViewModel.userSession = nil
//                }
//            } catch let signOutError as NSError {
//                print("Error signing out: %@", signOutError)
//            }
            loadMessagesIfNeeded()
        }
        .onChange(of: authViewModel.isLoading) { _ in
            loadMessagesIfNeeded()
        }
        .onChange(of: callManager.show) { _ in
            withAnimation {
                showTopView = callManager.show
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

