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
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var chatViewModel: ChatViewModel

    var body: some View {
        Group {
            switch authViewModel.userState {
            case .loggedOut:
                AuthView()
            case .loading, .loggedIn:
                TabsView()
            case .profileEditRequired:
                EditProfileView()
            case .blocked(let reason):
                BlockedView(text: reason)
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
