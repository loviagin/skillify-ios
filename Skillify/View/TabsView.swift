//
//  TabsView.swift
//  Skillify
//
//  Created by Ilia Loviagin on 11/15/24.
//

import SwiftUI

struct TabsView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var chatViewModel: ChatViewModel

    var body: some View {
        TabView(selection: $authViewModel.selectedTab) {
            FeedMainView()
                .tabItem {
                    Label("Main", systemImage: "house")
                        .environment(\.symbolVariants, authViewModel.selectedTab == .home ? .fill : .none)
                }
                .tag(TabType.home)
            
            ChatsView()
                .tabItem {
                    Label("Chats", systemImage: "bubble.left.and.bubble.right")
                        .environment(\.symbolVariants, authViewModel.selectedTab == .chats ? .fill : .none)
                }
                .tag(TabType.chats)
                .badge(chatViewModel.countUnread())
            
            MarketView()
                .tabItem {
                    Label("Market", systemImage: "storefront")
                        .environment(\.symbolVariants, authViewModel.selectedTab == .market ? .fill : .none)
                }
                .tag(TabType.market)
            
            AccountView()
                .tabItem {
                    Label("Account", systemImage: "person")
                        .environment(\.symbolVariants, authViewModel.selectedTab == .account ? .fill : .none)
                }
                .tag(TabType.account)
        }
    }
}

#Preview {
    TabsView()
}
