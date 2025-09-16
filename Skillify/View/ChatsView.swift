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
    @State private var activeUsers: [User] = []
        
    var body: some View {
        NavigationStack {
            HeaderChatView()
            
            if !activeUsers.isEmpty {
                VStack {
                    Text("Active Now")
                        .font(.callout)
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(activeUsers) { user in
                                NavigationLink(destination: MessagesView(userId: user.id).toolbar(.hidden, for: .tabBar)) {
                                    ActiveUserView(u: user)
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                    }
                    
                    Divider()
                }
                .padding(.horizontal)
            }
            
            List {
                if chats.isEmpty {
                    ContentUnavailableView("No chats", systemImage: "bubble.middle.top")
                } else {
                    LazyVStack(spacing: 15) {
                        ForEach($chats, id: \.id) { chat in
                            ChatView(chat: chat)
                                .onTapGesture {
                                    withAnimation {
                                        showChat = chat.wrappedValue
                                    }
                                }
                                .contextMenu(ContextMenu(menuItems: {
                                    Menu {
                                        Button(role: .destructive) {
                                            viewModel.deleteChat(chatId: chat.id)
                                        } label: {
                                            Text("Confirm deleting")
                                        }
                                    } label: {
                                        Label("Delete chat", systemImage: "trash")
                                    }
                                }))
                        }
                    }
                }
            }
            .listStyle(.plain)
            .onAppear {
                self.chats = viewModel.chats.filter({ $0.type == .personal })
                self.activeUsers = viewModel.activeUsers
            }
            .onChange(of: viewModel.chats) { _, newValue in
                self.chats = newValue.filter({ $0.type == .personal })
            }
            .onChange(of: viewModel.activeUsers) { _, newValue in
                self.activeUsers = newValue
            }
            .refreshable {
                viewModel.refresh()
            }
            .navigationDestination(item: $showChat) { chat in
                MessagesView(chatId: chat.id)
                    .toolbar(.hidden, for: .tabBar)
            }
        }
    }
}

struct ActiveUserView: View {
    let u: User
    
    var body: some View {
        VStack(alignment: .center) {
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if UserHelper.avatars.contains(u.urlAvatar.split(separator: ":").first.map(String.init) ?? "") {
                        Image(u.urlAvatar.split(separator: ":").first.map(String.init) ?? "")
                            .resizable()
                            .foregroundColor(.gray)
                            .aspectRatio(contentMode: .fill)
                            .padding(.top, 10)
                            .frame(width: 60, height: 60)
                            .background(Color.fromRGBAString(u.urlAvatar.split(separator: ":").last.map(String.init) ?? "") ?? .blue.opacity(0.4))
                            .clipShape(Circle())
                    } else if let url = URL(string: u.urlAvatar) {
                        KFImage(url)
                            .resizable()
                            .placeholder {
                                Image("avatar1")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(Circle())
                                    .clipped()
                            }
                            .cacheMemoryOnly()
                            .loadDiskFileSynchronously()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                            .clipped()
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .foregroundColor(.gray)
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                    }
                }
                .overlay(Circle().stroke(LinearGradient(colors: [.blue, .red], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2))
                .padding(3)
                
                if u.online ?? false {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .offset(x: -4, y: -4)
                }
            }
            
            HStack(spacing: 3) {
                Text("\(u.first_name.count > 8 ? u.first_name.prefix(8) + "..." : u.first_name)")
                    .font(.caption)

                if let data = u.tags, data.contains("verified") {
                    Image("verify") 
                        .resizable()
                        .scaledToFill()
                        .frame(width: 15, height: 15)
                } else if let data = u.tags, data.contains("admin") {
                    Image("gold")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 15, height: 15)
                } else if UserHelper.isUserPro(u.proDate), let data = u.proData, let status = data.first(where: { $0.hasPrefix("status:") }) {
                    Image(systemName: String(status.split(separator: ":").last ?? Substring(status)))
                        .resizable()
                        .scaledToFill()
                        .frame(width: 15, height: 15)
                }
            }
        }
        .padding(.trailing, 5)
    }
}

struct ChatView: View {
    @EnvironmentObject private var viewModel: ChatViewModel
    @Binding var chat: Chat
    
    @State private var user: User? // not current user
    
    var body: some View {
        HStack {
            if let urlAvatar = user?.urlAvatar {
                Avatar2View(avatarUrl: urlAvatar, size: 60, maxHeight: 60, maxWidth: 60)
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
                        Text(chat.last.text)
                            .font(.callout)
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
             
            VStack(alignment: .trailing) {
                Text(getDate(date: chat.lastTime))
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .padding(.top)
                
                HStack(spacing: 0) {
                    if let unreads = viewModel.unreadsChatCount(for: chat.id) {
                        Text("\(unreads)")
                            .font(.caption)
                            .padding(8)
                            .background(.red.opacity(0.5))
                            .foregroundStyle(.white)
                            .clipShape(Circle())
                            .clipped()
                    } else if chat.last.userId == Auth.auth().currentUser?.uid { // last message is our
                        Image(systemName: "checkmark")
                            .resizable()
                            .frame(width: 10, height: 10)
                            .foregroundStyle(.blue)
                            .padding(.leading, 7)
                        
                        if chat.last.status == "read" {
                            Image(systemName: "checkmark")
                                .resizable()
                                .frame(width: 10, height: 10)
                                .foregroundStyle(.blue)
                                .padding(.leading, -7)
                        }
                    }
                }
                
                Spacer()
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
    
    private func getDate(date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        let now = Date()
        
        // Проверяем, является ли дата сегодняшней
        if calendar.isDate(date, inSameDayAs: now) {
            // Если сообщение отправлено сегодня, возвращаем только время
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: date)
        }
        
        // Проверяем, является ли дата вчерашней
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(date, inSameDayAs: yesterday) {
            // Если сообщение отправлено вчера, возвращаем "Yesterday" и время
            formatter.dateFormat = "HH:mm"
            return "Yesterday, \(formatter.string(from: date))"
        }
        
        // Проверяем, является ли дата из текущей недели
        if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
            // Если сообщение отправлено на этой неделе, возвращаем день недели и время
            formatter.dateFormat = "EEEE, HH:mm"
            return formatter.string(from: date)
        }
        
        // Проверяем, является ли дата из текущего месяца
        if calendar.isDate(date, equalTo: now, toGranularity: .month) {
            // Если сообщение отправлено в этом месяце, возвращаем просто день и время
            formatter.dateFormat = "MMM d',' HH:mm"
            return formatter.string(from: date)
        }
        
        // Проверяем, является ли дата из текущего года
        if calendar.isDate(date, equalTo: now, toGranularity: .year) {
            // Если сообщение отправлено в этом году, возвращаем месяц и день
            formatter.dateFormat = "MMM d',' HH:mm"
            return formatter.string(from: date)
        } else {
            // Если сообщение отправлено в другом году, возвращаем месяц и год
            formatter.dateFormat = "MMM yyyy"
            return formatter.string(from: date)
        }
    }
}

#Preview {
    ChatsView()
        .environmentObject(ChatViewModel.mock)
        .environmentObject(AuthViewModel.mock)
}
