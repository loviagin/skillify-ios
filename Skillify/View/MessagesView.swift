//
//  MessagesView.swift
//  Skillify
//
//  Created by Ilia Loviagin on 19.12.2023.
//

import SwiftUI
import PhotosUI
import Kingfisher
import FirebaseAuth

struct MessagesView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var chatViewModel: ChatViewModel
    @EnvironmentObject private var userViewModel: AuthViewModel

    @StateObject private var viewModel = MessagesViewModel()
    
    @State var chatId = ""
    @State var userId = ""
    
    @State private var messages: [Message] = []
    @State private var user: User?
    @State private var text = ""
    @State private var theme = "theme1"
    
    @State private var showProfile = false
    @State private var replyMessage: Message?
    @State private var editMessage: Message?
    
    @State var selectedImages: [UIImage] = []
    @State var selectedVideos: [URL] = []
    @State var audioFileURL: URL?
    @State var audioLevels: [Float] = []
    
    @FocusState var focusing: ChatFocus?

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    ForEach($messages, id: \.id) { item in
                        NewChatItemView(
                            message: item,
                            chatId: chatId,
                            isCurrent: isCurrentUser(item: item.wrappedValue),
                            replyMessage: $replyMessage,
                            editMessage: $editMessage
                        )
                        .environmentObject(viewModel)
                        .id(item.wrappedValue.id)
                        .padding(.horizontal)
                    }
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if let lastItem = messages.last {
                            withAnimation {
                                proxy.scrollTo(lastItem.id, anchor: .bottom)
                            }
                        }
                    }
                }
                .onChange(of: messages) { _, _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if let lastItem = messages.last {
                            withAnimation {
                                proxy.scrollTo(lastItem.id, anchor: .bottom)
                            }
                        }
                    }
                }
                .onChange(of: viewModel.goToMessage) { _, newValue in
                    if let newValue {
                        withAnimation {
                            proxy.scrollTo(newValue, anchor: .top)
                            viewModel.goToMessage = nil
                        }
                    }
                }
            }
            .scrollIndicators(.never)
            .onTapGesture {
                withAnimation {
                    focusing = nil
                }
            }
            
            //MARK: - Bottom toolbar (messages field, send button)
            VStack(alignment: .leading) {
                if let text = isUserBlocked() {
                    Label(text, systemImage: "exclamationmark.triangle")
                        .frame(maxWidth: .infinity)
                        .padding(.top, 10)
                        .ignoresSafeArea()
                } else {
                    if let message = replyMessage {
                        HStack(alignment: .center) {
                            VStack(alignment: .leading) {
                                Text(isCurrentUser(item: message) ?
                                     (userViewModel.currentUser?.first_name ?? "") : (user?.first_name ?? "Support"))
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.blue)
                                
                                HStack(alignment: .center) {
                                    Image(systemName: "arrowshape.turn.up.left")
                                    
                                    Text(message.text ?? "🏞️ attachment")
                                        .lineLimit(2)
                                }
                                .padding(.bottom, 5)
                            }
                            
                            Spacer()
                            
                            Button {
                                withAnimation {
                                    replyMessage = nil
                                }
                            } label: {
                                Image(systemName: "xmark")
                            }
                        }
                    }
                    
                    if editMessage != nil {
                        HStack(alignment: .center) {
                            VStack(alignment: .leading) {
                                HStack(alignment: .center) {
                                    Image(systemName: "pencil")
                                    
                                    Text("Edit message: ")
                                        .fontWeight(.bold)
                                        .font(.caption)
                                        .foregroundStyle(.blue)
                                }
                                .padding(.bottom, 5)
                            }
                            
                            Spacer()
                            
                            Button {
                                withAnimation {
                                    editMessage = nil
                                }
                            } label: {
                                Image(systemName: "xmark")
                            }
                        }
                    }
                    
                    BottomBarChatView(text: $text, focusing: $focusing, sendAction: { sendChat() }, selectedImages: $selectedImages, selectedVideos: $selectedVideos, audioFileURL: $audioFileURL, audioLevels: $audioLevels)
                }
            }
            .padding(10)
            .background(.background)
        }
        .background(Image(theme).resizable().scaledToFill().ignoresSafeArea())
        .toolbarRole(.editor)
        .toolbar {
            //MARK: - Top toolbar name
            ToolbarItem(placement: .topBarLeading) {
                HStack(alignment: .center, spacing: 0) {
                    ZStack(alignment: .bottomTrailing) {
                        Avatar2View(avatarUrl: user?.urlAvatar ?? "", size: 40, maxHeight: 40, maxWidth: 40)
                        
                        if let user = user, user.online == true {
                            Circle()
                                .fill(.green)
                                .frame(width: 10, height: 10)
                        }
                    }
                    .padding(.leading, -15)
                    .padding(.trailing, 12)
                    
                    if isSystem() {
                        Text("Support")
                            .fontWeight(.bold)
                            .lineLimit(1)
                        
                    } else {
                        Text("\(user?.first_name ?? " ") \(user?.last_name ?? "")")
                            .fontWeight(.bold)
                            .lineLimit(1)
                            .onTapGesture {
                                if !isSystem() {
                                    withAnimation {
                                        showProfile = true
                                    }
                                }
                            }
                    }
                    
                    if isSystem() {
                        Image(.verify)
                            .resizable()
                            .frame(width: 15, height: 15)
                    } else if let user = user, let _ = user.tags?.first(where: { $0 == "admin" }) {
                        Image(.gold)
                            .resizable()
                            .frame(width: 15, height: 15)
                    } else if let user = user, let _ = user.tags?.first(where: { $0 == "verified" }) {
                        Image(.verify)
                            .resizable()
                            .frame(width: 15, height: 15)
                    }
                }
                .padding(.bottom, 5)
            }
            
            //MARK: - Top toolbar action button
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if !chatId.isEmpty {
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
                    
                    //MARK: - блокирование пользователя
                    if let blockedUsers = userViewModel.currentUser?.blockedUsers, blockedUsers.contains(userId) {
                        Button("Unblock user", systemImage: "person") {
                            userViewModel.unblockUser(userId: userId)
                        }
                    } else {
                        // Если пользователь не заблокирован
                        Button("Block user", systemImage: "person.slash") {
                            userViewModel.blockUser(userId: userId)
                            dismiss()
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
        .onChange(of: viewModel.messages) { oldValue, newValue in
            self.messages = newValue
        }
        .onChange(of: editMessage) { _, newValue in
            if let newValue {
                withAnimation {
                    text = newValue.text ?? ""
                    focusing = .textField
                }
            } else {
                withAnimation {
                    text = ""
                    focusing = nil
                }
            }
        }
        .onChange(of: replyMessage) { _, new in
            if new != nil {
                withAnimation {
                    focusing = .textField
                }
            } else {
                withAnimation {
                    focusing = nil
                }
            }
        }
        .sheet(isPresented: $showProfile) {
            ProfileView(user: user!)
        }
        .onDisappear {
            viewModel.detachListener()
        }
    }
    
    func isUserBlocked() -> String? {
        if let currentUser = userViewModel.currentUser, let receiver = user {
            if currentUser.blockedUsers.contains(receiver.id) {
                return "You was blocked this user"
            } else if receiver.blockedUsers.contains(currentUser.id) {
                return "The user was blocked you"
            }
        }

        return nil
    }
    
    private func sendChat() {
        guard let currentUser = userViewModel.currentUser else {
            withAnimation {
                text = "Only authorized user can send messages"
                
                DispatchQueue.main.async {
                    text = ""
                }
            }
            
            return
        }
        
        //MARK: - проверка что есть или текст или медиа
        if text.isEmpty && selectedImages.isEmpty && selectedVideos.isEmpty && audioFileURL == nil {
            return
        } else if let message = editMessage, !chatId.isEmpty {
            viewModel.editTextMessage(chatId: chatId, messageId: message.id, newText: text)
            
            withAnimation {
                editMessage = nil
                text = ""
            }
            
            return
        }
    
        var message = Message(
            userId: currentUser.id,
            text: text.isEmpty ? nil : text,
            messageType: .text,
            status: "sent",
            time: Date(),
            reply: replyMessage?.id
        )
        
        var newChat: Chat? = nil
        var imageData: [Data] = []
        
        if audioFileURL != nil {
            message.messageType = .audio
            message.text = nil
            message.info = audioLevels
        } else if !selectedImages.isEmpty {
            message.messageType = .photo
            
            for image in selectedImages {
                guard let data = image.jpegData(compressionQuality: 0.8) else { return }
                
                imageData.append(data)
            }
            
            selectedImages.removeAll()
        } else if !selectedVideos.isEmpty {
            message.messageType = .video
        }
        
        //MARK: - в список сообщений добавляется новое сообщение до его отправки (если чат не новый)
        if !chatId.isEmpty {
            messages.append(message)
            print("не новый чат")
        } else if !userId.isEmpty {
            print("чат новый")
            
            var text: String {
                if message.messageType == .audio {
                    return "Voice message"
                } else if message.messageType == .photo {
                    return "🏞️ photo"
                } else if message.messageType == .video {
                    return "🏞️ video"
                }
                
                return message.text ?? "🏞️ attachment"
            }
            
            newChat = Chat(
                id: isSystem() ? "Support\(Auth.auth().currentUser?.uid ?? "")" : UUID().uuidString,
                users: [
                    currentUser.id,
                    userId
                ],
                last: LastData(text: text, userId: currentUser.id, status: "sent"),
                lastTime: Date(),
                type: isSystem() ? .privateGroup : .personal
            )
            
            chatId = newChat!.id
            viewModel.fetchMessages(for: chatId)
        }
        
        viewModel.sendMessage(
            chatId: chatId,
            message: message,
            chat: newChat,
            imageData: imageData.isEmpty ? nil : imageData,
            videoList: selectedVideos.isEmpty ? nil : selectedVideos,
            audio: audioFileURL,
            userName: "\(currentUser.first_name) \(currentUser.last_name)"
        )
        
        withAnimation {
            text = ""
            replyMessage = nil
            selectedVideos.removeAll()
            audioFileURL = nil
        }
    }
    
    private func isCurrentUser(item: Message) -> Bool {
        return item.userId == (userViewModel.currentUser?.id ?? "")
    }
    
    private func appearAction() {
        if isSystem() {
            if let chat = chatViewModel.chats.first(where: {
                $0.id == "\(userId)\(Auth.auth().currentUser?.uid ?? "")"
            }) { // existing chat
                self.chatId = chat.id
                viewModel.fetchMessages(for: chatId)
            }
        } else if chatId.isEmpty && !userId.isEmpty { // it's a new chat
            viewModel.getChatIdByUserId(userId: userId, currentId: (userViewModel.currentUser?.id ?? "")) { chatId in
                if let chatId {
                    self.chatId = chatId
                    viewModel.fetchMessages(for: chatId)
                }
                
                viewModel.getUser(userId: userId) { user in
                    if let user {
                        self.user = user
                        print("set user")
                    } else {
                        self.user = userViewModel.currentUser
                    }
                }
            }
        } else if !chatId.isEmpty && userId.isEmpty { // it's not a new chat
            viewModel.getUserIdByChatId(chatId: chatId, currentId: (userViewModel.currentUser?.id ?? "")) { userId in
                if let userId {
                    self.userId = userId
                    viewModel.fetchMessages(for: chatId)
                    viewModel.getUser(userId: userId) { user in
                        if let user {
                            self.user = user
                        }
                    }
                }
            }
        } else {
            self.text = "error"
        }
        
        self.messages = viewModel.messages
        
        getBackground()
    }
    
    private func getBackground() {
        if let theme = UserDefaults.standard.string(forKey: "chatTheme\(chatId)") {
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
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: MessagesViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    @Binding var message: Message
    @State var chatId: String
    @State var isCurrent: Bool
    @Binding var replyMessage: Message?
    @Binding var editMessage: Message?
    
    @State private var offset: CGFloat = 0
    @State private var user: User? = nil
        
    var body: some View {
        HStack {
            if isCurrent { // our message
                Spacer()
            }
            
            VStack(alignment: isCurrent ? .trailing : .leading) {
                if let replyId = message.reply, let replyMessage = viewModel.messages.first(where: { $0.id == replyId }) {
                    Text(replyMessage.text ?? "🏞️ attachment")
                        .font(.caption)
                        .lineLimit(1)
                        .foregroundStyle(.primary.opacity(0.7))
                        .onTapGesture {
                            withAnimation {
                                viewModel.goToMessage = replyId
                            }
                        }
                    
                    Divider()
                } else if let forward = message.forward {
                    Text("Forwarded from: \(forward)")
                        .font(.caption)
                        .lineLimit(1)
                        .foregroundStyle(.primary.opacity(0.7))
                    
                    Divider()
                }
                
                if message.messageType == .photo, let media = message.media, !media.isEmpty {
                    FlexibleGridView(media: media)
                        .padding(.bottom, 5)
                }
                
                if message.messageType == .video, let media = message.media, !media.isEmpty {
                    FlexibleVideoView(media: media)
                        .padding(.bottom, 5)
                }
                
                if let text = message.text {
                    Text(text)
                        .multilineTextAlignment(isCurrent ? .trailing : .leading)
                }
                
                if message.messageType == .audio, let media = message.media?.first, let info = message.info, let url = URL(string: media) {
                    AudioMessageView(audioURL: url, audioLevels: info, current: isCurrent)
                }
                
                HStack(alignment: .bottom, spacing: 0) {
                    if let emojiArray = message.emoji {
                        ForEach(viewModel.groupEmojisAndUsers(from: emojiArray), id: \.emoji) { group in
                            HStack(spacing: 0) {
                                Text(group.emoji)
                                    .font(.callout)
                                    .padding(5)
                                    .clipShape(Circle())
                                    .padding(.trailing, 5)
                                
                                if group.userIds.count > 2 {
                                    Text("\(group.userIds.count)")
                                        .font(.callout)
                                        .foregroundStyle(isCurrent ? .blue : .white)
                                        .padding(.trailing, 8)
                                        .padding(.leading, -5)
                                } else {
                                    ForEach(group.userIds, id: \.self) { userId in
                                        Avatar2View(
                                            avatarUrl: isCurrentUser(userId: userId) ? (authViewModel.currentUser?.urlAvatar ?? "avatar1") : (user?.urlAvatar ?? "avatar1"),
                                            size: 30, maxHeight: 30)
                                            .overlay(
                                                Circle().stroke(Color.white, lineWidth: 2)
                                            )
                                            .padding(.leading, -8)
                                    }
                                }
                            }
                            .fixedSize()
                            .background(isCurrent ? Color.white : Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 50))
                            .onTapGesture {
                                withAnimation {
                                    viewModel.addEmojiToMessage(chatId: chatId, messageId: message.id, emoji: group.emoji, userId: authViewModel.currentUser?.id ?? "")
                                }
                            }
                            .padding(.trailing)
                        }
                    }
                    
                    Text(getDate(message: message))
                        .font(.caption)
                        .foregroundColor(isCurrent ? .white : .gray)
                    
                    Group {
                        if isCurrent {
                            Image(systemName: "checkmark")
                                .resizable()
                                .frame(width: 10, height: 10)
                                .padding(.leading, 7)
                            
                            if message.status == "read" {
                                Image(systemName: "checkmark")
                                    .resizable()
                                    .frame(width: 10, height: 10)
                                    .padding(.leading, -7)
                            }
                        }
                    }
                    .padding(.bottom, 3)
                }
            }
            .padding(.vertical)
            .padding(.horizontal, 15)
            .background(isCurrent ? Color.blue : Color.lightBlue)
            .foregroundColor(isCurrent ? .white : .black)
            .contextMenu {
                ControlGroup {
                    Button("❤️") {
                        viewModel.addEmojiToMessage(chatId: chatId, messageId: message.id, emoji: "❤️", userId: (authViewModel.currentUser?.id ?? ""))
                    }
                    
                    Button("🔥") {
                        viewModel.addEmojiToMessage(chatId: chatId, messageId: message.id, emoji: "🔥", userId: (authViewModel.currentUser?.id ?? ""))
                    }
                    
                    Button("😂") {
                        viewModel.addEmojiToMessage(chatId: chatId, messageId: message.id, emoji: "😂", userId: (authViewModel.currentUser?.id ?? ""))
                    }
                    
                    Button("😵‍💫") {
                        viewModel.addEmojiToMessage(chatId: chatId, messageId: message.id, emoji: "😵‍💫", userId: (authViewModel.currentUser?.id ?? ""))
                    }
                }
                .controlGroupStyle(.compactMenu)
                
                Button("Reply", systemImage: "arrowshape.turn.up.left") {
                    withAnimation {
                        editMessage = nil
                        replyMessage = message
                    }
                }
                
                if let text = message.text {
                    Button("Copy", systemImage: "doc.on.doc") {
                        UIPasteboard.general.string = text
                    }
                }
                
                if isCurrent {
                    if message.messageType != .audio {
                        Button("Edit", systemImage: "square.and.pencil") {
                            withAnimation {
                                replyMessage = nil
                                editMessage = message
                            }
                        }
                    }
                    
                    Menu {
                        Button("Confirm deleting", systemImage: "trash", role: .destructive) {
                            viewModel.deleteMessage(chatId: chatId, messageId: message.id) { info in
                                if let info, info == "deleted chat" {
                                    dismiss()
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "trash")
                            .tint(.red)
                        Text("Delete")
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .frame(minWidth: 50, maxWidth: 300, alignment: isCurrent ? .trailing : .leading)
            
            if !isCurrent { // not our message
                Spacer()
            }
            
            if offset < 0 {
                let iconSize = 5+(22*(-offset / 80))
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
        .padding(.vertical, 5)
        .offset(x: offset)
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    if gesture.translation.width < -30 {
                        // Ограничение максимального значения свайпа
                        offset = max(gesture.translation.width, -80)
                    }
                }
                .onEnded { gesture in
                    if gesture.translation.width < -80 && gesture.translation.width < -30 {
                        withAnimation {
                            replyMessage = message
                        }
                        
                        let generator = UIImpactFeedbackGenerator(style: .heavy)
                        generator.impactOccurred()
                    }
                    withAnimation {
                        offset = 0
                    }
                }
        )
        .onAppear {
            if !message.userId.isEmpty && message.userId != (authViewModel.currentUser?.id ?? "") && message.userId != "Support" {
                viewModel.getUser(userId: message.userId) { user in
                    if let user {
                        self.user = user
                    }
                }
            } else {
                print("messageId \(message.id)")
            }
        }
    }
    
    private func isCurrentUser(userId: String) -> Bool {
        if userId == (Auth.auth().currentUser?.uid ?? "") {
            return true
        }
        
        return false
    }
    
    private func getDate(message: Message) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        let now = Date()
        
        // Проверяем, является ли дата сегодняшней
        if calendar.isDate(message.time, inSameDayAs: now) {
            // Если сообщение отправлено сегодня, возвращаем только время
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: message.time)
        }
        
        // Проверяем, является ли дата вчерашней
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(message.time, inSameDayAs: yesterday) {
            // Если сообщение отправлено вчера, возвращаем "Yesterday" и время
            formatter.dateFormat = "HH:mm"
            return "Yesterday, \(formatter.string(from: message.time))"
        }
        
        // Проверяем, является ли дата из текущей недели
        if calendar.isDate(message.time, equalTo: now, toGranularity: .weekOfYear) {
            // Если сообщение отправлено на этой неделе, возвращаем день недели и время
            formatter.dateFormat = "EEEE, HH:mm"
            return formatter.string(from: message.time)
        }
        
        // Проверяем, является ли дата из текущего месяца
        if calendar.isDate(message.time, equalTo: now, toGranularity: .month) {
            // Если сообщение отправлено в этом месяце, возвращаем просто день и время
            formatter.dateFormat = "MMM d',' HH:mm"
            return formatter.string(from: message.time)
        }
        
        // Проверяем, является ли дата из текущего года
        if calendar.isDate(message.time, equalTo: now, toGranularity: .year) {
            // Если сообщение отправлено в этом году, возвращаем месяц и день
            formatter.dateFormat = "MMM d',' HH:mm"
            return formatter.string(from: message.time)
        } else {
            // Если сообщение отправлено в другом году, возвращаем месяц и год
            formatter.dateFormat = "MMM yyyy"
            return formatter.string(from: message.time)
        }
    }
}

#Preview {
    NavigationStack {
        MessagesView(userId: "Support")
            .environmentObject(ChatViewModel.mock)
            .environmentObject(AuthViewModel.mock)
    }
}
