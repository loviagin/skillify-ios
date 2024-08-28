//
//  NewChatView.swift
//  Skillify
//
//  Created by Ilia Loviagin on 8/2/24.
//
//
//import SwiftUI
//import UIKit
//import FirebaseAuth
//
//struct NewChatView: View {
//    @EnvironmentObject private var viewModel: MessagesViewModel
//    @EnvironmentObject private var authViewModel: AuthViewModel
//    
//    @State var userId: String
//    
//    @State private var user: User?
//    @State private var chatId: String?
//    @State private var text = ""
//    @State private var theme = "theme1"
//    
//    @State private var showProfile = false
//    @State private var replyMessage: Message?
////    @State private var editMessage: Message?
//    @State private var imageMedia: [UIImage]?
//    
//    var body: some View {
//        VStack(spacing: 0) {
//            ScrollViewReader { proxy in
//                ScrollView {
//                    if let chatId, let chat = viewModel.chats.first(where: { $0.id == chatId }), !chat.messages.isEmpty {
//                        // Преобразуем значения словаря сообщений в массив и отсортируем их по дате
//                        let sortedMessages = chat.messages.values.sorted { $0.date < $1.date }
//                        
//                        ForEach(sortedMessages, id: \.id) { item in
//                            NewChatItemView(message: item, chatId: chatId, isCurrent: isCurrentUser(item: item), replyMessage: $replyMessage)
//                                .id(item.id)
//                                .padding(.horizontal)
//                                .padding(.top, 10)
//                        }
//                    }
//                }
//                .onAppear {
//                    if let chatId,
//                       let chat = viewModel.chats.first(where: { $0.id == chatId }) {
//                        // Преобразуем значения словаря сообщений в массив и сортируем по дате
//                        let sortedMessages = chat.messages.values.sorted { $0.date < $1.date }
//                        if let lastItem = sortedMessages.last {
//                            proxy.scrollTo(lastItem.id, anchor: .bottom)
//                        }
//                    }
//                }
//                .onChange(of: viewModel.chats.first(where: { $0.id == (chatId ?? "") })?.messages) { _, _ in
//                    if let chatId,
//                       let chat = viewModel.chats.first(where: { $0.id == chatId }) {
//                        // Преобразуем значения словаря сообщений в массив и сортируем по дате
//                        let sortedMessages = chat.messages.values.sorted { $0.date < $1.date }
//                        if let lastItem = sortedMessages.last {
//                            proxy.scrollTo(lastItem.id, anchor: .bottom)
//                        }
//                    }
//                }
//            }
//            .scrollIndicators(.never)
//            
//            //MARK: - Bottom toolbar (messages field, send button)
//            VStack(alignment: .leading) {
//                if let message = replyMessage {
//                    HStack(alignment: .center) {
//                        VStack(alignment: .leading) {
//                            Text(isCurrentUser(item: message) ?
//                                 (authViewModel.currentUser?.first_name ?? "") : (user?.first_name ?? "Support"))
//                            .font(.caption)
//                            .fontWeight(.bold)
//                            .foregroundStyle(Color.blue)
//                            HStack(alignment: .center) {
//                                Image(systemName: "arrowshape.turn.up.left")
//                                
//                                Text(message.text ?? "🏞️ attachment")
//                                    .lineLimit(2)
//                            }                    
//                            .padding(.bottom, 5)
//                        }
//                        
//                        Spacer()
//                        
//                        Button {
//                            withAnimation {
//                                replyMessage = nil
//                            }
//                        } label: {
//                            Image(systemName: "xmark")
//                        }
//                    }
//                }
//                
//                if let text = isUserBlocked() {
//                    Label(text, systemImage: "exclamationmark.triangle")
//                        .frame(maxWidth: .infinity)
//                        .padding(.top, 10)
//                        .ignoresSafeArea()
//                } else {
//                    BottomBarChatView(text: $text, sendAction: { sendChat() })
//                }
//            }
//            .padding(10)
//            .background(.background)
//        }
//        .background(Image(theme).resizable().scaledToFill().ignoresSafeArea())
//        .toolbar {
//            //MARK: - Top toolbar name
//            ToolbarItem(placement: .principal) {
//                HStack(alignment: .center) {
//                    if let user = user, user.online == true {
//                        Circle()
//                            .fill(.green)
//                            .frame(width: 10, height: 10)
//                    }
//                    
//                    Text(isSystem() ? userId : (user?.first_name ?? ""))
//                        .fontWeight(.bold)
//                        .onTapGesture {
//                            if !isSystem() {
//                                withAnimation {
//                                    showProfile = true
//                                }
//                            }
//                        }
//                    
//                    if isSystem() {
//                        Image(.verify)
//                            .resizable()
//                            .frame(width: 15, height: 15)
//                    } else if let user = user, let _ = user.tags?.first(where: { $0 == "admin" }) {
//                        Image(.gold)
//                            .resizable()
//                            .frame(width: 15, height: 15)
//                    } else if let user = user, let _ = user.tags?.first(where: { $0 == "verified" }) {
//                        Image(.verify)
//                            .resizable()
//                            .frame(width: 15, height: 15)
//                    }
//                }
//            }
//            
//            //MARK: - Top toolbar action button
//            ToolbarItem(placement: .topBarTrailing) {
//                Menu {
//                    if let chatId {
//                        Button("Change theme", systemImage: "paintbrush") {
//                            if theme == "theme1" {
//                                UserDefaults.standard.set("theme2", forKey: "chatTheme\(chatId)")
//                                withAnimation {
//                                    self.theme = "theme2"
//                                }
//                            } else {
//                                UserDefaults.standard.set("theme1", forKey: "chatTheme\(chatId)")
//                                withAnimation {
//                                    self.theme = "theme1"
//                                }
//                            }
//                        }
//                    }
//                } label: {
//                    Image(systemName: "ellipsis.circle")
//                }
//
//            }
//        }
//        .toolbarBackground(.visible, for: .navigationBar)
//        .toolbar(.visible, for: .navigationBar)
//        .onAppear {
//            appearAction()
//        }
//        .sheet(isPresented: $showProfile) {
//            ProfileView(user: user!)
//        }
//    }
//    
//    func isUserBlocked() -> String? {
//        if let currentUser = authViewModel.currentUser, let receiver = user {
//            if currentUser.blockedUsers.contains(receiver.id) {
//                return "You was blocked this user"
//            } else if receiver.blockedUsers.contains(currentUser.id) {
//                return "The user was blocked you"
//            }
//        }
//        
//        return nil
//    }
//    
//    private func sendChat() {
//        //MARK: - проверка что есть или текст или медиа
//        if text.isEmpty {
//            print("\(text) this is text")
//            return
//        }
//        
//        let message = Message(
//            cUid: authViewModel.currentUser?.id ?? "",
//            text: text.isEmpty ? nil : text,
//            date: Date(),
//            status: "u",
//            reply: replyMessage?.id ?? nil,
//            type: MessageType.text
//        )
//        
//        var newChat: Chat? = nil
//        
//        //MARK: - в список сообщений добавляется новое сообщение до его отправки (если чат не новый)
//        if let chatId, let index = viewModel.chats.firstIndex(where: { $0.id == chatId }) {
//            viewModel.chats[index].messages[message.id] = message
//            print("не новый чат")
//        } else if let user = authViewModel.currentUser {
//            print("чат новый")
//            
//            newChat = Chat(
//                last: LastData(userId: message.cUid, status: "u", text: text, date: Date()),
//                messages: [message.id: message],
//                members: [
//                    Member(userId: user.id, level: .usually), // user.id = current user
//                    Member(userId: userId, level: .admin)
//                ],
//                type: isSystem() ? .privateGroup : .personal
//            )
//            
//            chatId = newChat!.id
//        }
//        
//        if isSystem(), let cUser = authViewModel.currentUser {
//            viewModel.sendSupportMessage(chatId: chatId, message: message, user: cUser, chat: newChat)
//        } else if let cUser = authViewModel.currentUser, let user {
////            viewModel.sendMessage(id: chatId, chat: chat, cUser: cUser, receiverUser: user, message: newMessage)
//        }
//        
//        withAnimation {
//            text = ""
//            replyMessage = nil
//        }
//    }
//    
//    private func isCurrentUser(item: Message) -> Bool {
//        return item.cUid == (authViewModel.currentUser?.id ?? "")
//    }
//    
//    private func appearAction() {
//        //MARK: - ВКЛЮЧИТЬ ДЛЯ ПРОДА !!!
//        self.chatId = viewModel.getChatId(cUid: (authViewModel.currentUser?.id ?? ""), userId: self.userId)
////        chatId = "Support"
//        
//        if !isSystem() {
//            viewModel.getUserByUserId(userId: userId) { user in
//                if let user {
//                    self.user = user
//                }
//            }
//        }
//        
//        getBackground()
////        viewModel.setReadToAllMessages(chatId, currentUserId: (authViewModel.currentUser?.id ?? ""))
//    }
//    
//    private func getBackground() {
//        if let chatId, let theme = UserDefaults.standard.string(forKey: "chatTheme\(chatId)") {
//            withAnimation {
//                self.theme = theme
//            }
//        }
//    }
//    
//    private func isSystem() -> Bool {
//        return userId == "Support"
//    }
//}
//
//struct NewChatItemView: View {
//    @EnvironmentObject private var viewModel: MessagesViewModel
//
//    @State var message: Message
//    @State var chatId: String
//    @State var isCurrent: Bool
//    @Binding var replyMessage: Message?
//    
//    @State private var offset: CGFloat = 0
//    
//    let minIconSize: CGFloat = 5
//    let maxIconSize: CGFloat = 27
//            
//    var body: some View {
//        HStack {
//            if isCurrent { // our message
//                Spacer()
//            }
//            
//            VStack(alignment: isCurrent ? .trailing : .leading) {
//                if let reply = message.reply {
//                    Text(reply)
//                        .font(.callout)
//                        .lineLimit(1)
//                }
//                
//                if let text = message.text {
//                    Text(text)
//                        .multilineTextAlignment(isCurrent ? .trailing : .leading)
//                } else {
//                    Label("Content not available", systemImage: "exclamationmark.triangle")
//                        .multilineTextAlignment(isCurrent ? .trailing : .leading)
//                        .foregroundStyle(.gray)
//                }
//                
//                HStack(spacing: 0) {
//                    if let emoji = message.emoji {
//                        Text(emoji)
//                            .font(.callout)
//                            .padding(5)
//                            .background(.white)
//                            .clipShape(Circle())
//                            .padding(.trailing)
//                    }
//                    
//                    Text(getDate(message: message))
//                        .font(.caption)
//                        .foregroundColor(isCurrent ? .white : .gray)
//                    
//                    if isCurrent {
//                        Image(systemName: "checkmark")
//                            .resizable()
//                            .frame(width: 10, height: 10)
//                            .padding(.leading, 7)
//                        
//                        if message.status == "r" { // r - for PROD
//                            Image(systemName: "checkmark")
//                                .resizable()
//                                .frame(width: 10, height: 10)
//                                .padding(.leading, -7)
//                        }
//                    }
//                }
//            }
//            .padding(.vertical, 10)
//            .padding(.horizontal, 15)
//            .background(isCurrent ? .blue : .white)
//            .foregroundColor(isCurrent ? .white : .black)
//            .contextMenu {
//                ControlGroup {
//                    Button("❤️") {
////                        viewModel.setEmoji(id: id, chat: chat, emoji: "❤️")
//                    }
//                    
//                    Button("🔥") {
////                        viewModel.setEmoji(id: id, chat: chat, emoji: "🔥") 
//                    }
//                    
//                    Button("😂") {
////                        viewModel.setEmoji(id: id, chat: chat, emoji: "😂")
//                    }
//                    
//                    Button("😵‍💫") {
////                        viewModel.setEmoji(id: id, chat: chat, emoji: "😵‍💫")
//                    }
//                }
//                .controlGroupStyle(.compactMenu)
//                
//                Button("Reply", systemImage: "arrowshape.turn.up.left") {
//                    withAnimation {
//                        replyMessage = message
//                    }
//                }
//                
//                if let text = message.text {
//                    Button("Copy", systemImage: "doc.on.doc") {
//                        UIPasteboard.general.string = text
//                    }
//                }
//                
//                if isCurrent {
////                    Button("Edit", systemImage: "square.and.pencil") {
////                        
////                    }
//                    
//                    Button("Delete", systemImage: "trash", role: .destructive) {
////                        viewModel.deleteMessage(chatId: id, messageId: chat.id)
//                    }
//                }
//            }
//            .clipShape(RoundedRectangle(cornerRadius: 15))
//            .frame(minWidth: 50, maxWidth: 300, alignment: isCurrent ? .trailing : .leading)
//            
//            if !isCurrent { // not our message
//                Spacer()
//            }
//            
//            if offset < 0 {
//                let iconSize = minIconSize + (maxIconSize - minIconSize) * (-offset / 80)
//                Image(systemName: "arrowshape.turn.up.left")
//                    .resizable()
//                    .padding(7)
//                    .background(Color.gray.opacity(0.3))
//                    .foregroundColor(.primary.opacity(0.7))
//                    .frame(width: iconSize, height: iconSize)
//                    .clipShape(Circle())
//                    .padding(.leading)
//            }
//        }
//        .frame(maxWidth: .infinity)
//        .contentShape(Rectangle())
//        .offset(x: offset)
//        .gesture(
//            DragGesture()
//                .onChanged { gesture in
//                    if gesture.translation.width < -30 {
//                        // Ограничение максимального значения свайпа
//                        offset = max(gesture.translation.width, -80)
//                    }
//                }
//                .onEnded { gesture in
//                    if gesture.translation.width < -80 && gesture.translation.width < -30 {
//                        withAnimation {
//                            replyMessage = message
//                        }
//                        
//                        let generator = UIImpactFeedbackGenerator(style: .heavy)
//                        generator.impactOccurred()
//                    }
//                    withAnimation {
//                        offset = 0
//                    }
//                }
//        )
//    }
//    
//    private func getDate(message: Message) -> String {
//        let formatter = DateFormatter()
//        
//        // Определяем, в текущем ли году эта дата
//        let calendar = Calendar.current
//        if calendar.isDate(message.date, equalTo: Date(), toGranularity: .year) {
//            formatter.dateFormat = "MMM d',' HH:mm"
//        } else {
//            formatter.dateFormat = "MMM d, yyyy',' HH:mm"
//        }
//        
//        return formatter.string(from: message.date)
//    }
//}
//
//struct BottomBarChatView: View {
//    @Binding var text: String
//    
//    var sendAction: () -> Void
//    
//    var body: some View {
//        HStack(spacing: 10) {
////            Button {
////                 
////            } label: {
////                Image(systemName: "paperclip")
////                    .resizable()
////                    .frame(width: 23, height: 23)
////            }
//            
//            TextField("Type ...", text: $text)
//                .padding(5)
//                .background(.lGray)
//                .clipShape(RoundedRectangle(cornerRadius: 10))
//                .lineLimit(4)
//                .submitLabel(.send)
//                .onSubmit {
//                    sendAction()
//                }
//            
//            Button {
//                sendAction()
//            } label: {
//                Image(systemName: "paperplane")
//                    .resizable()
//                    .frame(width: 23, height: 23)
//            }
//        }
//    }
//}
//
//#Preview {
//    NewChatView(userId: "Support")
//        .environmentObject(AuthViewModel.mock)
//        .environmentObject(MessagesViewModel.mock)
//        .toolbar(.visible, for: .navigationBar)
//}
