//
//  TabsView.swift
//  Skillify
//
//  Created by Ilia Loviagin on 11/15/24.
//

import SwiftUI

struct TabsView: View {
    @EnvironmentObject private var viewModel: AuthViewModel
    @EnvironmentObject private var chatViewModel: ChatViewModel

    @State var blocked: Int = 0
    
    @State var showSelfSkill = false
    @State var showLearningSkill = false
    
    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            FeedMainView(extraSkillsList: [])
                .tabItem {
                    Label("Main", systemImage: "house")
                        .environment(\.symbolVariants, viewModel.selectedTab == .home ? .fill : .none)
                }
                .tag(TabType.home)
            
            ChatsView()
                .tabItem {
                    Label("Chats", systemImage: "bubble.left.and.bubble.right")
                        .environment(\.symbolVariants, viewModel.selectedTab == .chats ? .fill : .none)
                }
                .tag(TabType.chats)
                .badge(chatViewModel.countUnread())
            
            EmptyChatsView()
                .tabItem {
                    Label("Discover", systemImage: "magnifyingglass")
                        .environment(\.symbolVariants, viewModel.selectedTab == .discovery ? .fill : .none)
                }
                .tag(TabType.discovery)
            
            AccountView(blocked: $blocked)
                .tabItem {
                    Label("Account", systemImage: "person")
                        .environment(\.symbolVariants, viewModel.selectedTab == .account ? .fill : .none)
                }
                .toolbar(.visible, for: .tabBar)
                .tag(TabType.account)
        }
        .background(Color.gray)
        .navigationDestination(isPresented: $showSelfSkill) {
            SelfSkillsView(authViewModel: viewModel, isRegistration: true)
        }
        .navigationDestination(isPresented: $showLearningSkill) {
            LearningSkillsView(authViewModel: viewModel, isRegistration: true)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                if viewModel.currentUser?.selfSkills.isEmpty ?? false {
                    showSelfSkill = true
                } else if viewModel.currentUser?.learningSkills.isEmpty ?? false {
                    showLearningSkill = true
                }
            }
        }
    }
}

#Preview {
    TabsView()
}
