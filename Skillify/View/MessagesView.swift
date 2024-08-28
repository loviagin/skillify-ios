//
//  MessagesView.swift
//  Skillify
//
//  Created by Ilia Loviagin on 19.12.2023.
//

import SwiftUI
import PhotosUI
import Kingfisher

struct MessagesView: View {
    @StateObject private var viewModel = MessagesViewModel()
    @EnvironmentObject private var userViewModel: AuthViewModel
    
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
                    if let lastItem = messages.last {
                        proxy.scrollTo(lastItem.id, anchor: .bottom)
                    }
                }
                .onChange(of: messages) { _, _ in
                    if let lastItem = messages.last {
                        proxy.scrollTo(lastItem.id, anchor: .bottom)
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
                    
                    BottomBarChatView(text: $text, focusing: $focusing, sendAction: { sendChat() }, selectedImages: $selectedImages)
                }
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

                    Text(user?.first_name ?? " ")
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
            if let new {
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
        if text.isEmpty && selectedImages.isEmpty {
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
        
        if !selectedImages.isEmpty {
            message.messageType = .photo
            
            for image in selectedImages {
                guard let data = image.jpegData(compressionQuality: 0.8) else { return }
                
                imageData.append(data)
            }
            
            selectedImages.removeAll()
        }
        
        //MARK: - в список сообщений добавляется новое сообщение до его отправки (если чат не новый)
        if !chatId.isEmpty {
            messages.append(message)
            print("не новый чат")
        } else if !userId.isEmpty {
            print("чат новый")
            
            newChat = Chat(
                users: [
                    currentUser.id,
                    userId
                ],
                last: LastData(text: message.text ?? "🏞️ attachment", userId: currentUser.id, status: "sent"),
                lastTime: Date()
            )
            
            chatId = newChat!.id
            viewModel.fetchMessages(for: chatId)
        }
        
        viewModel.sendMessage(
            chatId: chatId,
            message: message,
            chat: newChat,
            imageData: imageData.isEmpty ? nil : imageData,
            userName: "\(currentUser.first_name) \(currentUser.last_name)"
        )
        
        withAnimation {
            text = ""
            replyMessage = nil
        }
    }
    
    private func isCurrentUser(item: Message) -> Bool {
        return item.userId == (userViewModel.currentUser?.id ?? "")
    }
    
    private func appearAction() {
        if chatId.isEmpty && !userId.isEmpty { // it's a new chat
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
    @EnvironmentObject private var viewModel: MessagesViewModel
    
    @Binding var message: Message
    @State var chatId: String
    @State var isCurrent: Bool
    @Binding var replyMessage: Message?
    @Binding var editMessage: Message?
    
    @State private var offset: CGFloat = 0
        
    var body: some View {
        HStack {
            if isCurrent { // our message
                Spacer()
            }
            
            VStack(alignment: isCurrent ? .trailing : .leading) {
                if let media = message.media, !media.isEmpty {
                    FlexibleGridView(media: media)
                        .padding(.bottom, 5)
                }
               
                if let replyId = message.reply, let replyMessage = viewModel.messages.first(where: { $0.id == replyId }) {
                    Text(replyMessage.text ?? "🏞️ attachment")
                        .font(.caption)
                        .lineLimit(1)
                        .foregroundStyle(.primary.opacity(0.7))
                    
                    Divider()
                }
                
                if let text = message.text {
                    Text(text)
                        .multilineTextAlignment(isCurrent ? .trailing : .leading)
                }
                
                HStack(spacing: 0) {
                    if let emoji = message.emoji {
                        Text(emoji)
                            .font(.callout)
                            .padding(5)
                            .background(.white)
                            .clipShape(Circle())
                            .padding(.trailing)
                    }
                    
                    Text(getDate(message: message))
                        .font(.caption)
                        .foregroundColor(isCurrent ? .white : .gray)
                    
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
            }
            .padding(.vertical)
            .padding(.horizontal, 15)
            .background(isCurrent ? .blue : .white)
            .foregroundColor(isCurrent ? .white : .black)
            .contextMenu {
                ControlGroup {
                    Button("❤️") {
                        viewModel.addEmojiToMessage(chatId: chatId, messageId: message.id, emoji: "❤️")
                    }
                    
                    Button("🔥") {
                        viewModel.addEmojiToMessage(chatId: chatId, messageId: message.id, emoji: "🔥")
                    }
                    
                    Button("😂") {
                        viewModel.addEmojiToMessage(chatId: chatId, messageId: message.id, emoji: "😂")
                    }
                    
                    Button("😵‍💫") {
                        viewModel.addEmojiToMessage(chatId: chatId, messageId: message.id, emoji: "😵‍💫")
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
                    Button("Edit", systemImage: "square.and.pencil") {
                        withAnimation {
                            replyMessage = nil
                            editMessage = message
                        }
                    }
                    
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        viewModel.deleteMessage(chatId: chatId, messageId: message.id)
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
    }
    
    private func getDate(message: Message) -> String {
        let formatter = DateFormatter()
        
        // Определяем, в текущем ли году эта дата
        let calendar = Calendar.current
        if calendar.isDate(message.time, equalTo: Date(), toGranularity: .year) {
            formatter.dateFormat = "MMM d',' HH:mm"
        } else {
            formatter.dateFormat = "MMM d, yyyy',' HH:mm"
        }
        
        return formatter.string(from: message.time)
    }
}

struct BottomBarChatView: View {
    @Binding var text: String
    @FocusState.Binding var focusing: ChatFocus?
    var sendAction: () -> Void
    
    @State private var showAttach = false
    
    @Binding var selectedImages: [UIImage]
    @State var showPhotoPicker = false
    
    var body: some View {
        VStack {
            if !selectedImages.isEmpty {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(Array(selectedImages.enumerated()), id: \.element) { index, image in
                            ZStack {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 15))
                                    .clipped()

                                Button {
                                    selectedImages.remove(at: index)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .resizable()
                                        .scaledToFill()
                                        .foregroundStyle(.gray)
                                        .frame(width: 24, height: 24)
                                }
                            }
                        }
                    }
                }
                .scrollIndicators(.never)
            }
            
            HStack(spacing: 10) {
                Button {
                    withAnimation {
                        showAttach = true
                    }
                } label: {
                    Image(systemName: "paperclip")
                        .resizable()
                        .frame(width: 23, height: 23)
                }
                
                TextField("Type ...", text: $text)
                    .padding(5)
                    .background(.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .lineLimit(4)
                    .submitLabel(.send)
                    .focused($focusing, equals: ChatFocus.textField)
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
        .confirmationDialog("Choose attachment type", isPresented: $showAttach) {
            Button("Photo") {
                withAnimation {
                    showPhotoPicker = true
                }
            }
        }
        .sheet(isPresented: $showPhotoPicker) {
            ImageChatPicker(selectedImages: $selectedImages)
                .ignoresSafeArea()
        }
    }
}

struct FlexibleGridView: View {
    var media: [String]

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let spacing: CGFloat = 5
            
            switch media.count {
            case 1:
                KFImage(URL(string: media[0]))
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .clipped()
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
            case 2:
                HStack(spacing: spacing) {
                    ForEach(media, id: \.self) { urlString in
                        KFImage(URL(string: urlString))
                            .resizable()
                            .scaledToFill()
                            .frame(width: (size.width - spacing) / 2, height: (size.height - spacing) / 2)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .clipped()
                    }
                }
                
            case 3:
                VStack(spacing: spacing) {
                    KFImage(URL(string: media[0]))
                        .resizable()
                        .scaledToFill()
                        .frame(width: size.width, height: size.height * 2 / 3)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .clipped()
                    
                    HStack(spacing: spacing) {
                        KFImage(URL(string: media[1]))
                            .resizable()
                            .scaledToFill()
                            .frame(width: (size.width - spacing) / 2, height: (size.height / 3))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .clipped()
                        
                        KFImage(URL(string: media[2]))
                            .resizable()
                            .scaledToFill()
                            .frame(width: (size.width - spacing) / 2, height: (size.height / 3))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .clipped()
                    }
                }
                
            case 4:
                let gridItems = Array(repeating: GridItem(.flexible(), spacing: spacing), count: 2)
                
                LazyVGrid(columns: gridItems, spacing: spacing) {
                    ForEach(media, id: \.self) { urlString in
                        KFImage(URL(string: urlString))
                            .resizable()
                            .scaledToFill()
                            .frame(width: (size.width - spacing) / 2, height: (size.height - spacing) / 2)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .clipped()
                    }
                }
                
            case 5:
                VStack(spacing: spacing) {
                    KFImage(URL(string: media[0]))
                        .resizable()
                        .scaledToFill()
                        .frame(width: size.width, height: size.height / 2)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .clipped()
                    
                    let gridItems = Array(repeating: GridItem(.flexible(), spacing: spacing), count: 2)
                    
                    LazyVGrid(columns: gridItems, spacing: spacing) {
                        ForEach(Array(media[1...4]), id: \.self) { urlString in
                            KFImage(URL(string: urlString))
                                .resizable()
                                .scaledToFill()
                                .frame(width: (size.width - spacing) / 2, height: (size.height / 4))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .clipped()
                        }
                    }
                }
                
            default:
                EmptyView()
            }
        }
        .frame(height: calculateHeight(for: media.count, width: UIScreen.main.bounds.width - 80))
    }
    
    private func calculateHeight(for count: Int, width: CGFloat) -> CGFloat {
        let spacing: CGFloat = 5

        switch count {
        case 1:
            return width
        case 2:
            return (width / 2)
        case 3:
            return (width * 2 / 3) + (width / 3) + spacing
        case 4:
            return (width / 2) * 2 + spacing
        case 5:
            return (width / 2) + ((width / 4) * 2) + spacing
        default:
            return 0
        }
    }
}

enum ChatFocus {
    case textField
}

#Preview {
    ChatsView(showChat: Chat())
        .environmentObject(ChatViewModel.mock)
        .environmentObject(AuthViewModel.mock)
}
