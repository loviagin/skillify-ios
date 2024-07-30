//
//  MessagesView.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 19.12.2023.
//

import SwiftUI
import FirebaseFirestore
import FirebaseFirestore

struct MessagesView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var messagesViewModel: MessagesViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State var showMessage = false
    @Binding var showChats: Bool
    @State var messageId: String?
    @State var user: User?
    
    var body: some View {
        NavigationStack {
            VStack {
                List(messagesViewModel.messages, id: \.id) { message in
                    MessageItemView(message: message, messageId: $messageId, cUser: $user, showMessage: $showMessage)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                let messageId = message.id
                                let userId = authViewModel.currentUser!.id // ID текущего пользователя
                                
                                let userDocRef = Firestore.firestore().collection("users").document(userId)
                                let ind = authViewModel.currentUser!.messages.firstIndex(where: { $0.values.contains(where: { $0 == messageId }) })
                                if let ind {
                                    authViewModel.currentUser!.messages.remove(at: ind)
                                }
                                
                                // Получаем текущий массив сообщений пользователя, затем обновляем его, удаляя нужный элемент
                                userDocRef.getDocument { (document, error) in
                                    if let document = document, document.exists, let messages = document.data()?["messages"] as? [[String: Any]] {
                                        // Находим индекс элемента для удаления
                                        if let indexToRemove = messages.firstIndex(where: { $0.values.contains(where: { $0 as? String == messageId }) }) {
                                            var updatedMessages = messages
                                            updatedMessages.remove(at: indexToRemove)
                                            
                                            // Обновляем документ, устанавливая обновленный массив
                                            userDocRef.updateData(["messages": updatedMessages]) { err in
                                                if let err = err {
                                                    print("Error updating document: \(err)")
                                                } else {
                                                    print("Document successfully updated")
                                                }
                                            }
                                        }
                                    } else {
                                        print("Document does not exist or failed to fetch messages.")
                                    }
                                }
                                Firestore.firestore().collection("messages").document(message.id).delete()
                                Task {
                                    await messagesViewModel.loadMessages(self.authViewModel)
                                }
                            } label: {
                                Label("Delete chat", systemImage: "trash.circle.fill")
                            }
                        }
                }
                .onAppear() {
                    showMessage = false
                    if !messagesViewModel.isLoading {
                        Task {
                            await messagesViewModel.loadMessages(self.authViewModel)
                        }
                    }
                    checkDestination()
                }
                .onChange(of: authViewModel.destination) { _ in
                    checkDestination()
                }
                .refreshable {
                    Task {
                        await messagesViewModel.loadMessages(self.authViewModel)
                    }
                }
            }
            .navigationTitle("Messages")
        }
        .navigationDestination(isPresented: $showMessage) {
            if let id = messageId, let u = user, !id.isEmpty {
                ChatView(userId: id, showMessage: $showMessage, user: u).toolbar(.hidden, for: .tabBar)
                    .onDisappear {
                        messageId = nil
                        user = nil
                    }
            }
        }
        
    }
    
    func checkDestination() {
        if let destination = authViewModel.destination {
            Task {
                await messagesViewModel.loadMessages(self.authViewModel)
            }
            
            if let dest = destination.components(separatedBy: "/").last {
                let id = messagesViewModel.messages.first(where: { $0.id == String(dest) })?.uids[0] == authViewModel.currentUser?.id ? messagesViewModel.messages.first(where: { $0.id == String(dest) })?.uids[1] : messagesViewModel.messages.first(where: { $0.id == String(dest) })?.uids[0]
                print(id ?? "no id")
                if let id {
                    Task {
                        let docRef = Firestore.firestore().collection("users").document(id)
                        
                        do {
                            let u0 = try await docRef.getDocument(as: User.self)
                            self.user = u0
                            self.messageId = String(dest)
                            self.showMessage = true
                        } catch {
                            print("Error decoding city: \(error)")
                        }
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                showMessage = false
            }
        }
    }
}

struct MessageItemView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    var message: Message
    
    @State var user: User?
    @State var id: String?
    
    @Binding var messageId: String?
    @Binding var cUser: User?
    @Binding var showMessage: Bool
    
    var body: some View {
        Button {
            messageId = message.id
            cUser = user != nil ? user! : User()
            showMessage = true
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
                        
                        let t1 = message.lastData[0] == authViewModel.currentUser?.id ? "you:" : ">"
                        let t2 = message.lastData[1]
                        Text("\(t1) \(t2)")
                            .lineLimit(1)
                            .font(.callout)
                    }
                    .padding(.leading, 5)
                } else {
                    ProgressView()
                }
                Spacer()
                if message.lastData.count >= 3 {
                    if message.lastData[0] != authViewModel.currentUser!.id && message.lastData[2] == "u" {
                        //                    print("\(message.id) -- message")
                        Circle()
                            .frame(width: 10, height: 10)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .foregroundStyle(.primary)
        .padding(.vertical, 5)
        .onAppear() {
            id = message.uids[0] == authViewModel.currentUser?.id ? message.uids[1] : message.uids[0]
            Task {
                let docRef = Firestore.firestore().collection("users").document(id ?? "OC45RCDwA9XHefuIMFo8ks5on1a2")
                
                do {
                    let u0 = try await docRef.getDocument(as: User.self)
                    self.user = u0
                } catch {
                    print("Error decoding city: \(error)")
                }
            }
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
    MessagesView(showChats: .constant(true))
        .environmentObject(AuthViewModel.mock)
        .environmentObject(MessagesViewModel.mock)
}
