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
    @EnvironmentObject private var viewModel: AuthViewModel
    @EnvironmentObject private var chatViewModel: ChatViewModel

    @State var blocked: Int = 0
    
//    @State var showSelfSkill = false
//    @State var showLearningSkill = false
    
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
            
            DiscoverView()
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
//        .background(Color.gray)
//        .navigationDestination(isPresented: $showSelfSkill) {
//            SelfSkillsView(authViewModel: viewModel, isRegistration: true)
//        }
//        .navigationDestination(isPresented: $showLearningSkill) {
//            LearningSkillsView(authViewModel: viewModel, isRegistration: true)
//        }
//        .onAppear {
//            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//                if viewModel.currentUser?.selfSkills.isEmpty ?? false {
//                    showSelfSkill = true
//                } else if viewModel.currentUser?.learningSkills.isEmpty ?? false {
//                    showLearningSkill = true
//                }
//            }
//        }
    }
//    @EnvironmentObject var authViewModel: AuthViewModel
//        
//    @State var profileUser: User? = nil
//    @State var userId: MessageUser?
//    
//    var body: some View {
//        NavigationStack{
//            Group {
//                if authViewModel.isLoading {
//                    ProgressView()
//                } else if Auth.auth().currentUser != nil {
//                    MainView()
//                } else {
//                    AuthView()
//                }
//            }
//            .onOpenURL { url in
//                if Auth.auth().currentUser != nil {
//                    if let scheme = url.scheme, scheme == "skillify" {
//                        let destination = url.absoluteString.split(separator: "://").last
//                        
//                        let dest = destination?.components(separatedBy: "/").first
//                        if dest == "m", let dest = destination?.components(separatedBy: "/").last {
//                            authViewModel.selectedTab = .chats
//                            userId = MessageUser(id: dest)
//                        } else if let _ = destination?.contains("@") {
//                            loadUser(String(destination?.components(separatedBy: "@").last ?? ""))
//                        }
//                    }
//                }
//            }
//            .navigationDestination(item: $profileUser) { user in
//                ProfileView(user: user)
//            }
//            .navigationDestination(item: $userId) { user in
//                MessagesView(userId: user.id)
//            }
//        }
//        .onAppear {
//            //                        do {
//            //                try Auth.auth().signOut()
//            //            } catch let signOutError as NSError {
//            //                print("Error signing out: %@", signOutError)
//            //            }
//        }
//    }
//    
//    private func loadUser(_ user: String) {
//        Firestore.firestore().collection("users")
//            .whereField("nickname", isEqualTo: user)
//            .getDocuments 
//        { snap, error in
//            if let error {
//                print(error)
//            } else {
//                self.profileUser = try? snap?.documents.first?.data(as: User.self)
//            }
//        }
//    }
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
