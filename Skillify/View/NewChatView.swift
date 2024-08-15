//
//  NewChatView.swift
//  Skillify
//
//  Created by Ilia Loviagin on 8/2/24.
//

import SwiftUI
import UIKit
import FirebaseAuth

struct NewChatView: View {
    @EnvironmentObject private var viewModel: MessagesViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    @State var userId: String /*= "Support"*/
    
    @State private var user: User?
    @State private var chatId: String?
    @State private var text = ""
    @State private var theme = "theme1"
    
    @State private var showProfile = false
    @State private var replyChat: Chat?
    @State private var editChat: Chat?
    @State private var imageMedia: [UIImage]?
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    if let chatId,
                        let messages = viewModel.messages.first(where: { $0.id == chatId }),
                       !messages.messages.isEmpty
                    {
                        ForEach(messages.messages, id: \.id) { item in
                            NewChatItemView(chat: item, isCurrent: isCurrentUser(item: item), replyChat: $replyChat, editChat: $editChat)
                                .id(item.id)
                                .padding(.horizontal)
                                .padding(.top, 10)
                        }
                    }
                }
                .onAppear {
                    if let chatId,
                       let messages = viewModel.messages.first(where: { $0.id == chatId }),
                       let lastItem = messages.messages.last
                    {
                        proxy.scrollTo(lastItem.id, anchor: .bottom)
                    }
                }
                .onChange(of: viewModel.messages.first(where: { $0.id == (chatId ?? "") })?.messages) { _, _ in
                    if let chatId,
                       let messages = viewModel.messages.first(where: { $0.id == chatId }),
                       let lastItem = messages.messages.last {
                        proxy.scrollTo(lastItem.id, anchor: .bottom)
                    }
                }
            }
            .scrollIndicators(.never)
            
            //MARK: - Bottom toolbar (messages field, send button)
            VStack(alignment: .leading) {
                if let chat = replyChat {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading) {
                            Text(isCurrentUser(item: chat) ?
                                 (authViewModel.currentUser?.first_name ?? "") : (user?.first_name ?? "Support"))
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.blue)
                            HStack(alignment: .center) {
                                Image(systemName: "arrowshape.turn.up.left")
                                
                                Text(chat.text ?? "")
                                    .lineLimit(2)
                            }                    
                            .padding(.bottom, 5)
                        }
                        
                        Spacer()
                        
                        Button {
                            withAnimation {
                                replyChat = nil
                            }
                        } label: {
                            Image(systemName: "xmark")
                        }
                    }
                }
                
                BottomBarChatView(text: $text, sendAction: { sendChat() })
            }
            .padding(10)
            .background(.background)
        }
        .background(Image(theme).resizable().scaledToFill().ignoresSafeArea())
        .toolbar {
            //MARK: - Top toolbar name
            ToolbarItem(placement: .principal) {
                HStack(alignment: .center) {
                    if let user = user, user.online == true {
                        Circle()
                            .fill(.green)
                            .frame(width: 10, height: 10)
                    }
                    
                    Text(isSystem() ? userId : (user?.first_name ?? ""))
                        .fontWeight(.bold)
                        .onTapGesture {
                            if !isSystem() {
                                withAnimation {
                                    showProfile = true
                                }
                            }
                        }
                    
                    if isSystem() {
                        Image(.verify)
                            .resizable()
                            .frame(width: 15, height: 15)
                    } else if let user = user, let _ = user.tags?.contains("admin") {
                        Image(.gold)
                            .resizable()
                            .frame(width: 15, height: 15)
                    } else if let user = user, let _ = user.tags?.contains("verified") {
                        Image(.verify)
                            .resizable()
                            .frame(width: 15, height: 15)
                    }
                }
            }
            
            //MARK: - Top toolbar action button
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if let chatId {
                        Button("Change theme", systemImage: "paintbrush") {
                            if theme == "theme1" {
                                UserDefaults.standard.set("theme2", forKey: "chatTheme\(chatId)")
                                withAnimation {
                                    self.theme = "theme2"
                                }
                            } else {
                                UserDefaults.standard.set("theme1", forKey: "chatTheme\(chatId)")
                                withAnimation {
                                    self.theme = "theme1"
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }

            }
        }
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar(.visible, for: .navigationBar)
        .onAppear {
            appearAction()
        }
        .sheet(isPresented: $showProfile) {
            ProfileView(/*showProfile: $showProfile, */user: user!)
        }
    }
    
    private func sendChat() {
        //MARK: - проверка что есть или текст или медиа
        if text.isEmpty {
            print("\(text) this is text")
            return
        }
        
        let chat = Chat(
            cUid: authViewModel.currentUser?.id ?? "",
            text: text.isEmpty ? nil : text,
            date: Date(),
            status: "u",
            reply: replyChat?.id ?? nil,
            type: .text
        )
        
        var newMessage: Message? = nil
        
        //MARK: - в список сообщений добавляется новое сообщение до его отправки (если чат не новый)
        if let chatId, let index = viewModel.messages.firstIndex(where: { $0.id == chatId }) {
            viewModel.messages[index].messages.append(chat)
            print("не новый чат")
        } else if let user = authViewModel.currentUser {
            print("чат новый")
            
            newMessage = Message(
                last: LastData(userId: chat.cUid, status: "u", text: text),
                messages: [chat],
                date: Date(),
                members: [
                    Member(userId: user.id, level: .usually), // user.id = current user
                    Member(userId: userId, level: .admin)
                ],
                type: isSystem() ? .privateGroup : .personal
            )
            
            print("это первый \(newMessage!.id)")
            chatId = newMessage!.id
        }
        
        if isSystem(), let cUser = authViewModel.currentUser {
            viewModel.sendSupportMessage(id: chatId, chat: chat, user: cUser, message: newMessage)
        } else if let cUser = authViewModel.currentUser, let user {
            viewModel.sendMessage(id: chatId, chat: chat, cUser: cUser, receiverUser: user, message: newMessage)
        }
        
        text = ""
    }
    
    private func isCurrentUser(item: Chat) -> Bool {
        return item.cUid == (authViewModel.currentUser?.id ?? "")
    }
    
    private func appearAction() {
        //MARK: - ВКЛЮЧИТЬ ДЛЯ ПРОДА !!!
        self.chatId = viewModel.getMessageId(cUid: (authViewModel.currentUser?.id ?? ""), userId: self.userId)
//        chatId = "Support"
        
        if !isSystem() {
            viewModel.getUserByUserId(userId: userId) { user in
                if let user {
                    self.user = user
                }
            }
        }
        
        getBackground()
        viewModel.setReadToAllMessages(chatId, currentUserId: (authViewModel.currentUser?.id ?? ""))
    }
    
    private func getBackground() {
        if let chatId, let theme = UserDefaults.standard.string(forKey: "chatTheme\(chatId)") {
            withAnimation {
                self.theme = theme
            }
        }
    }
    
    private func isSystem() -> Bool {
        return userId == "Support"
    }
}

struct NewChatItemView: View {
    @State var chat: Chat
    @State var isCurrent: Bool
    @Binding var replyChat: Chat?
    @Binding var editChat: Chat?
    
    @State private var offset: CGFloat = 0
    
    let minIconSize: CGFloat = 5
    let maxIconSize: CGFloat = 27
            
    var body: some View {
        HStack {
            if isCurrent { // our message
                Spacer()
            }
            
            VStack(alignment: isCurrent ? .trailing : .leading) {
                Text(chat.text ?? "")
                    .multilineTextAlignment(isCurrent ? .trailing : .leading)
                
                HStack(spacing: 0) {
                    Text(getDate(chat: chat))
                        .font(.caption)
                        .foregroundColor(isCurrent ? .white : .gray)
                    
                    if isCurrent {
                        Image(systemName: "checkmark")
                            .resizable()
                            .frame(width: 10, height: 10)
                            .padding(.leading, 7)
                        
                        if chat.status == "r" { // r - for PROD
                            Image(systemName: "checkmark")
                                .resizable()
                                .frame(width: 10, height: 10)
                                .padding(.leading, -7)
                        }
                    }
                }
                
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 15)
            .background(isCurrent ? .blue.opacity(0.9) : .white.opacity(0.9))
            .foregroundColor(isCurrent ? .white : .black)
            .contextMenu {
                ControlGroup {
                    Button("❤️") {
                        
                    }
                    
                    Button("🔥") {
                        
                    }
                    
                    Button("😂") {
                        
                    }
                    
                    Button("😵‍💫") {
                        
                    }
                }
                .controlGroupStyle(.compactMenu)
                
                Button("Reply", systemImage: "arrowshape.turn.up.left") {
                    
                }
                
                Button("Copy", systemImage: "doc.on.doc") {
                    
                }
                
                if isCurrent {
                    Button("Edit", systemImage: "square.and.pencil") {
                        
                    }
                    
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .frame(minWidth: 50, maxWidth: 300, alignment: isCurrent ? .trailing : .leading)
            
            if !isCurrent { // not our message
                Spacer()
            }
            
            if offset < 0 {
                let iconSize = minIconSize + (maxIconSize - minIconSize) * (-offset / 80)
                Image(systemName: "arrowshape.turn.up.left")
                    .resizable()
                    .padding(7)
                    .background(Color.gray.opacity(0.3))
                    .foregroundColor(.primary.opacity(0.7))
                    .frame(width: iconSize, height: iconSize)
                    .clipShape(Circle())
                    .padding(.leading)
            }
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .offset(x: offset)
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    if gesture.translation.width < 0 {
                        // Ограничение максимального значения свайпа
                        offset = max(gesture.translation.width, -80)
                    }
                }
                .onEnded { gesture in
                    if gesture.translation.width < -80 {
                        withAnimation {
                            replyChat = chat
                        }
                        
                        let generator = UIImpactFeedbackGenerator(style: .heavy)
                        generator.impactOccurred()
                    }
                    withAnimation {
                        offset = 0
                    }
                }
        )
    }
    
    private func getRead(_ status: String) -> Bool {
        if status == "r" {
            return true
        } else {
            return false
        }
    }
    
    private func getDate(chat: Chat) -> String {
        if let time = chat.time {
            let date = Date(timeIntervalSince1970: time)
            let formatter = DateFormatter()
            
            // Выбираем формат в зависимости от года
            formatter.dateFormat = Calendar.current.isDate(date, equalTo: Date(), toGranularity: .year) ? "MMM d 'at' HH:mm" : "MMM d, yyyy',' HH:mm"
            
            return formatter.string(from: date)
        } else if let date = chat.date {
            let formatter = DateFormatter()
            
            // Определяем, в текущем ли году эта дата
            let calendar = Calendar.current
            if calendar.isDate(date, equalTo: Date(), toGranularity: .year) {
                formatter.dateFormat = "MMM d',' HH:mm"
            } else {
                formatter.dateFormat = "MMM d, yyyy',' HH:mm"
            }
            
            return formatter.string(from: date)
        } else {
            return ""
        }
    }
}

struct BottomBarChatView: View {
    @Binding var text: String
    
    var sendAction: () -> Void
    
    var body: some View {
        HStack(spacing: 10) {
            Button {
                 
            } label: {
                Image(systemName: "paperclip")
                    .resizable()
                    .frame(width: 23, height: 23)
            }
            
            TextField("Type ...", text: $text)
                .padding(5)
                .background(.lGray)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .lineLimit(4)
                .submitLabel(.send)
                .onSubmit {
                    sendAction()
                }
            
            Button {
                sendAction()
            } label: {
                Image(systemName: "paperplane")
                    .resizable()
                    .frame(width: 23, height: 23)
            }
        }
    }
}

#Preview {
    NewChatView(userId: "Support")
        .environmentObject(AuthViewModel.mock)
        .environmentObject(MessagesViewModel.mock)
        .toolbar(.visible, for: .navigationBar)
}
