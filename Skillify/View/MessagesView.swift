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

    var body: some View {
        NavigationStack {
            VStack {
                List(messagesViewModel.messages, id: \.id) { message in
                    MessageItemView(message: message)
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
                            } label: {
                                Label("Delete chat", systemImage: "trash.circle.fill")
                            }
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
            .navigationTitle("Messages")
        }
    }
}

struct MessageItemView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    var message: Message
    
    @State var user: User?
    @State var id: String?
    var body: some View {
        NavigationLink(destination: ChatView(userId: message.id, user: user != nil ? user! : User()).toolbar(.hidden, for: .tabBar)) {
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
//                            .padding(.bottom)
                    }
                } else {
                    Image(systemName: "person")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
//                        .padding(10)
                        .background(.lGray)
                        .clipShape(Circle())
                }
                if user != nil {
                    VStack(alignment: .leading) {
                        Text("\(user?.first_name ?? "") \(user?.last_name ?? "")")
                            .font(.title3)
                            .lineLimit(1)
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
        .padding(.vertical, 5)
        .onAppear() {
            //            if message.uids[0] == "General Group" {
            //                    self.user = User(id: "", first_name: "General", last_name: "Group", email: "", nickname: "", phone: "", birthday: Date())
            //            }
            //            else {
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
            //            }
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
    MessagesView()
}
