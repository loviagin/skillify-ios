//
//  MainView.swift
//  Skillify
//
//  Created by Ilia Loviagin on 11/15/24.
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
        
    var body: some View {
        if authViewModel.isLoading {
            ProgressView()
        } else if authViewModel.currentUser?.nickname == "" {
            EditProfileView()
        } else if authViewModel.currentUser?.blocked ?? 0 > 3 || authViewModel.currentUser?.block != nil {
            BlockedView(text: authViewModel.currentUser?.block)
        } else {
            TabsView()
        }
    }
}

#Preview {
    MainView()
        .environmentObject(AuthViewModel.mock)
        .environmentObject(ChatViewModel.mock)
        .environmentObject(CallManager.mock)
}
