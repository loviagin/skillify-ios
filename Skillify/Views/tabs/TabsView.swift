//
//  TabsView.swift
//  Skillify
//
//  Created by Ilia Loviagin on 10/5/25.
//

import SwiftUI

struct TabsView: View {
    @EnvironmentObject private var viewModel: MainViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(AppTab.home)
            
            DiscoverView()
                .tabItem {
                    Label("Discover", systemImage: "safari")
                }
                .tag(AppTab.discover)
            
            AccountView(userViewModel: authViewModel.userViewModel)
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
                .tag(AppTab.account)
        }
    }
}

#Preview {
    TabsView()
}
