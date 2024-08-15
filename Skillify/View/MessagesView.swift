//
//  MessagesView.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 19.12.2023.
//

import SwiftUI
import FirebaseFirestore

struct MessagesView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var messagesViewModel: MessagesViewModel
    
    @State var showMessage: User?
    @State var messageId: String?
    @State var user: User?
    
    @State private var deleteChatShow = false
    
    var body: some View {
        NavigationStack {
            HStack {
                Text("Chats")
                    .font(.title2)
                    .foregroundStyle(.primary)
                    .padding()
                
                Spacer()
                
                NavigationLink(destination: NewChatView(userId: "Support")
                    .toolbar(.hidden, for: .tabBar)
                ) {
                    Image(systemName: "questionmark.bubble")
                }
                .padding()
            }
            List(messagesViewModel.messages.filter({ $0.type == .personal }), id: \.id) { message in
                MessageItemView(message: message, messageId: $messageId, cUser: $user, showMessage: $showMessage)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            deleteChatShow = true
                        } label: {
                            Label("Delete chat", systemImage: "trash.circle.fill")
                        }
                    }
                    .confirmationDialog("Are you sure you want to delete this chat?", isPresented: $deleteChatShow) {
                        Button(role: .destructive) {
                            Firestore.firestore().collection("messages").document(message.id).delete()
                            Task {
                                await messagesViewModel.loadMessages(self.authViewModel)
                            }
                            deleteChatShow = false
                        } label: {
                            Text("Delete chat")
                        }
                        
                        Button(role: .cancel) {
                            deleteChatShow = false
                        } label: {
                            Text("Cancel")
                        }
                    }
                    .onAppear() {
                        if !messagesViewModel.isLoading {
                            Task {
                                await messagesViewModel.loadMessages(self.authViewModel)
                            }
                        }
                    }
                    .refreshable {
                        Task {
                            await messagesViewModel.loadMessages(self.authViewModel)
                        }
                    }
            }
            .listStyle(.plain)
            .navigationDestination(item: $showMessage) { user in
                NewChatView(userId: user.id)
                    .toolbar(.hidden, for: .tabBar)
            }
        }
    }
}

struct MessageItemView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var viewModel: MessagesViewModel
    var message: Message
    
    @State var user: User?
    @State var id: String?
    
    @Binding var messageId: String?
    @Binding var cUser: User?
    @Binding var showMessage: User?
    
    var body: some View {
        Button {
            messageId = message.id
            cUser = user != nil ? user! : User()
            showMessage = user
        } label: {
            HStack {
                if user != nil {
                    if UserHelper.avatars.contains(user!.urlAvatar.split(separator: ":").first.map(String.init) ?? "") {
                        Image(user!.urlAvatar.split(separator: ":").first.map(String.init) ?? "")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .padding(.top, 10)
                            .frame(width: 50, height: 50)
                            .background(Color.fromRGBAString(user!.urlAvatar.split(separator: ":").last.map(String.init) ?? "") ?? .blue.opacity(0.4))
                            .clipShape(Circle())
                    } else if let url = URL(string: user!.urlAvatar) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                        } placeholder: {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .foregroundColor(.gray)
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                        }
                        .frame(width: 50, height: 50)
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .foregroundColor(.gray)
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    }
                } else {
                    Image(systemName: "person")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .background(.lGray)
                        .clipShape(Circle())
                }
                if user != nil {
                    VStack(alignment: .leading) {
                        HStack(spacing: 5) {
                            Text("\(user?.first_name ?? "") \(user?.last_name ?? "")")
                                .font(.title3)
                                .lineLimit(1)
                            if let data = user?.tags, data.contains("verified") {
                                Image("verify")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 20, height: 20)
                            } else if let data = user?.tags, data.contains("admin") {
                                Image("gold")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 20, height: 20)
                            } else if UserHelper.isUserPro(user?.pro), let data = user?.proData, let status = data.first(where: { $0.hasPrefix("status:") }) {
                                Image(systemName: String(status.split(separator: ":").last ?? Substring(status)))
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 20, height: 20)
                                    .foregroundColor(.brandBlue)
                            }
                        }
                        
                        let t1 = getLastUserId(item: message) == (authViewModel.currentUser?.id ?? "") ? "you:" : ">"
                        let t2 = getLastText(item: message)
                        Text("\(t1) \(t2)")
                            .lineLimit(1)
                            .font(.callout)
                    }
                    .padding(.leading, 5)
                } else {
                    ProgressView()
                }
                Spacer()
                if getLastStatus(item: message) == "u" &&
                    getLastUserId(item: message) != (authViewModel.currentUser?.id ?? "") {
                    Circle()
                        .frame(width: 10, height: 10)
                        .foregroundColor(.gray)
                    
                }
            }
        }
        .foregroundStyle(.primary)
        .padding(.vertical, 5)
        .onAppear {
            viewModel.getUserByMessageId(id: message.id) { user in
                if let user {
                    self.user = user
                }
            }
        }
    }
    
    private func getLastUserId(item: Message) -> String {
        if let last = message.last {
            return last.userId
        } else if let lastData = message.lastData, lastData.count >= 3 {
            return lastData[0]
        } else {
            return "User"
        }
    }
    
    private func getLastText(item: Message) -> String {
        if let last = message.last {
            return last.text
        } else if let lastData = message.lastData, lastData.count >= 3 {
            return lastData[1]
        } else {
            return ""
        }
    }
    
    private func getLastStatus(item: Message) -> String {
        if let last = message.last {
            return last.status
        } else if let lastData = message.lastData, lastData.count >= 3 {
            return lastData[2]
        } else {
            return "u"
        }
    }
    
    func truncateString(_ string: String, toLength length: Int) -> String {
        if string.count > length {
            let index = string.index(string.startIndex, offsetBy: length)
            return String(string[..<index]) + "..."
        } else {
            return string
        }
    }
}

#Preview {
    MessagesView(/*showChats: .constant(true)*/)
        .environmentObject(AuthViewModel.mock)
        .environmentObject(MessagesViewModel.mock)
}
