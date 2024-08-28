//
//  ChatView.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 23.12.2023.
//

import SwiftUI
import FirebaseAuth
import Kingfisher

struct ChatsView: View {
    @EnvironmentObject private var viewModel: ChatViewModel
    
    @State var showChat: Chat?
    
    @State private var chats: [Chat] = []
        
    var body: some View {
        NavigationStack {
            List {
                if chats.isEmpty {
                    ContentUnavailableView("No chats", systemImage: "bubble.middle.top")
                } else {
                    ForEach($chats, id: \.id) { chat in
                        ChatView(chat: chat)
                            .onTapGesture {
                                withAnimation {
                                    showChat = chat.wrappedValue
                                }
                            }
                    }
                }
            }
            .listStyle(.plain)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Chats")
                        .font(.title)
                        .bold()
                        .foregroundStyle(Color.primary)
                }
                
//                if Auth.auth().currentUser != nil {
//                    ToolbarItem(placement: .topBarTrailing) {
//                        Menu {
//                            Button("Message", systemImage: "bubble.left.and.text.bubble.right") {
//                                withAnimation {
//                                    showNewChat = true
//                                }
//                            }
//                        } label: {
//                            Image(systemName: "plus")
//                        }
//                    }
//                }
            }
            .navigationDestination(item: $showChat) { chat in
                MessagesView(chatId: chat.id)
                    .toolbar(.hidden, for: .tabBar)
            }
            .onAppear {
                self.chats = viewModel.chats
            }
            .onChange(of: viewModel.chats) { oldValue, newValue in
                self.chats = newValue
            }
        }
    }
}

struct ChatView: View {
    @EnvironmentObject private var viewModel: ChatViewModel
    @Binding var chat: Chat
    
    @State private var user: User?
    
    var body: some View {
        HStack {
            if let user {
                if UserHelper.avatars.contains(user.urlAvatar) {
                    Image(user.urlAvatar)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                } else if let url = URL(string: user.urlAvatar) {
                    KFImage(url)
                        .resizable()
                        .placeholder {
                            Image("avatar1")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 30, height: 30)
                                .clipShape(Circle())
                                .clipped()
                        }
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                        .clipped()
                }
            } else {
                Image("avatar1")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
            }
            
            VStack(alignment: .leading) {
                Group {
                    if let firstName = user?.first_name, let lastName = user?.last_name  {
                        Text("\(firstName) \(lastName)")
                    } else {
                        Text("Chat")
                    }
                }
                .font(.title3)
                .bold()
                
                Group {
                    if !chat.last.text.isEmpty {
                        Text("\(isCurrentUser(id: chat.last.userId) ? "you:" : ">") \(chat.last.text)")
                    } else {
                        Text("Chat created. Say hi 👋 ")
                            .foregroundStyle(.blue)
                    }
                }
                .foregroundStyle(.gray)
                .lineLimit(1)
            }
            .padding(.horizontal, 8)
            
            Spacer()
             
            if let unreads = viewModel.unreadsChatCount(for: chat.id) {
                Text("\(unreads)")
                    .font(.callout)
                    .padding(5)
                    .background(.blue.opacity(0.5))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .clipped()
            }
        }
        .background(.background)
        .onAppear {
            if !isGroupChat() { // if it's not a forum's chat
                viewModel.loadChatUser(chat: chat) { user in
                    if let user {
                        self.user = user
                    }
                }
            }
        }
    }
    
    func isCurrentUser(id: String) -> Bool {
        if let currentUser = Auth.auth().currentUser?.uid, currentUser == id {
            return true
        } else {
            return false
        }
    }
    
    func isGroupChat() -> Bool {
        if chat.users.count > 2 {
            return true
        }
        
        return false
    }
}

#Preview {
    ChatsView()
        .environmentObject(ChatViewModel.mock)
        .environmentObject(AuthViewModel.mock)
}
