//
//  ChatView.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 23.12.2023.
//

import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import AVFoundation
import PhotosUI
import AVKit
import UIKit

struct ChatView: View {
    @State var userId: String
    @Binding var showMessage: Bool
    @Environment(\.dismiss) private var dismiss
    var user: User
    
    @State var messageText = ""
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var mViewModel: MessagesViewModel
    @EnvironmentObject var callManager: CallManager
    @State private var messagesList: [Chat] = [Chat]()
    @FocusState private var isInputFieldFocused: Bool
    @State var replyMessage: Chat?
    @State var editMessage: Chat?
    
    @State var scrollTo = ""
    @State var bigImage: String?
    @State private var showDocumentPicker = false
    @State private var showPhotoPicker = false
    @State private var showActionSheet: Bool = false
    @State var photoPickerItem: PhotosPickerItem?
    @State private var documentURLs: [URL] = []
    @State private var scale: CGFloat = 1.0
    @State private var currentOffset: CGSize = .zero
    @State private var temporaryOffset: CGSize = .zero
    
    @State private var systemMessage: String? = nil
    @State private var showSafari = false
    @State private var showChangeTheme = false
    @State private var theme = "theme1"
    
    @State var showProfile = false
    
    var body: some View {
        if user.blocked ?? 0 > 3 {
            Text("Sorry, the user is blocked by administration")
        } else {
            ZStack {
                VStack (spacing: 0) {
                    ScrollViewReader { scrollViewProxy in
                        List {
                            if !messagesList.isEmpty || userId != "nil"{
                                ForEach(messagesList, id: \.id) { message in
                                    ChatItemView(message: message, user: user, userId: userId, replyMessage: $replyMessage, editMessage: $editMessage, messageText: $messageText, messagesList: $messagesList,
                                                 scrollTo: $scrollTo, bigImage: $bigImage)
                                    .padding([.leading, .trailing], 4)
                                    .padding([.top, .bottom], 0)
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                    .background(Color.clear)
                                }
                            }
                        }
                        .scrollIndicators(.hidden)
                        .onAppear {
                            if let lastMessage = messagesList.last {
                                withAnimation {
                                    scrollViewProxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: scrollTo) { _ in
                            withAnimation {
                                scrollViewProxy.scrollTo(scrollTo, anchor: .top)
                            }
                            scrollTo = ""
                        }
                        .onChange(of: messagesList) { _ in
                            if let lastMessage = messagesList.last {
                                withAnimation {
                                    scrollViewProxy.scrollTo(lastMessage.id)
                                }
                            }
                            updateStatusInMessages()
                        }
                        .listStyle(PlainListStyle())
                    }
                    .background(Image(theme).resizable().aspectRatio(contentMode: .fill).edgesIgnoringSafeArea(.all))
                    
                    if let message = systemMessage {
                        SystemMessageView(systemMessage: message)
                            .onTapGesture {
                                systemMessage = nil
                            }
                    }
                    
                    if let rep = replyMessage {
                        HStack {
                            Image(systemName: "arrowshape.turn.up.left.circle")
                            VStack(alignment: .leading) {
                                Text("Reply to \(rep.cUid == authViewModel.currentUser!.id ? "me" : user.first_name)")
                                    .fontWeight(.bold)
                                if let text = rep.text {
                                    Text(text).lineLimit(1)
                                } else {
                                    Text("🌄")
                                }
                            }
                            Spacer()
                            Button {
                                replyMessage = nil
                            } label: {
                                Image(systemName: "xmark")
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .padding(0)
                        .background(.main.opacity(0.6))
                        .cornerRadius(15)
                    }
                    
                    if let rep = editMessage {
                        HStack {
                            Image(systemName: "pencil.circle")
                            VStack(alignment: .leading) {
                                Text("Edit message")
                                    .fontWeight(.bold)
                                if let text = rep.text {
                                    Text(text).lineLimit(1)
                                }
                            }
                            Spacer()
                            Button {
                                editMessage = nil
                                messageText = ""
                            } label: {
                                Image(systemName: "xmark")
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .padding(0)
                        .background(.main.opacity(0.6))
                        .cornerRadius(15)
                    }
                    
                    HStack {
                        if let stringText = UserHelper.isMessagesBlocked(viewModel: authViewModel, user: user) {
                            Label {
                                Text("Sorry, \(stringText)")
                            } icon: {
                                Image(systemName: "circle.slash")
                                    .foregroundColor(.red)
                            }
                        } else {
                            if userId != "nil" {
                                Button {
                                    self.showActionSheet = true
                                } label: {
                                    Image(systemName: "folder")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 23)
                                }
                                .confirmationDialog("Select an option", isPresented: $showActionSheet, titleVisibility: .visible) {
                                    Button("Photo & video") {
                                        showPhotoPicker = true
                                    }
                                    Button("Any file") {
                                        self.showDocumentPicker = true
                                        // Здесь логика для выбора файла любого типа, например, через UIDocumentPickerViewController
                                    }
                                } message: {
                                    Text("Select what you want to upload.")
                                }
                                .sheet(isPresented: $showDocumentPicker) {
                                    DocumentPicker { urls in
                                        documentURLs = urls
                                        Task {
                                            for url in urls {
                                                await uploadFile(url: url)
                                            }
                                        }
                                    }
                                    .ignoresSafeArea()
                                }
                                .sheet(isPresented: $showPhotoPicker) {
                                    ImageVideoPicker(messagesList: $messagesList, authViewModel: authViewModel, sendMessage: { imageUrl in
                                        sendMessage(imageUrl: imageUrl)
                                    })
                                    .ignoresSafeArea()
                                }
                            }
                            PlaceholderTextEditor(placeholder: "Enter your message...", text: $messageText)
                                .frame(minHeight: 10, maxHeight: 80)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 5)
                                .border(.transparency, width: 1)
                                .background(.background)
                                .cornerRadius(15)
                                .fixedSize(horizontal: false, vertical: true)
                                .focused($isInputFieldFocused)
                            
                            Button {
                                if let ed = editMessage {
                                    updateMessage(messageId: editMessage!.id, text: messageText)
                                    let ind = messagesList.firstIndex(where: { $0.id == ed.id })
                                    
                                    if let index = ind {
                                        messagesList[index].text = messageText
                                    }
                                    
                                    editMessage = nil
                                    messageText = ""
                                } else if !messageText.isEmpty {
                                    if userId == "nil" {
                                        loadSaveMessage()
                                    } else {
                                        sendMessage(imageUrl: nil)
                                    }
                                }
                                
                                Task {
                                    await mViewModel.loadMessages(self.authViewModel)
                                }
                            } label: {
                                Image(systemName: /*messageText == "" ? "mic" : */"paperplane.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 23, height: 23)
                            }
                        } // if UserHelper.isMessagesBlocked()
                    } // HStack
                    .frame(maxWidth: .infinity, minHeight: 40)
                    .padding([.top, .leading, .trailing])
                    .ignoresSafeArea()
                    .background(.main.opacity(0.9))
                } // VStack (main)
                .onTapGesture {
                    self.isInputFieldFocused = false
                }
                .focused($isInputFieldFocused)
                .onAppear {
                    startListeningForMessages()
                    updateStatusInMessages()
                }
                .onChange(of: photoPickerItem) { _ in
                    Task {
                        await onChangeTask()
                    }
                }
                
                if let image = bigImage {
                    ZStack {
                        Rectangle()
                            .background(Color.gray.opacity(0.6))
                            .onTapGesture {
                                bigImage = nil
                                scale = 1.0
                                currentOffset = .zero
                                temporaryOffset = .zero
                            }
                        if let url = URL(string: image) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .scaleEffect(scale)
                                        .offset(currentOffset)
                                        .gesture(magnificationGesture.simultaneously(with: dragGesture))
                                case .failure(_), .empty:
                                    Image("placeholder") // Ваш плейсхолдер
                                        .resizable()
                                        .scaledToFit()
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .onTapGesture(count: 2) {
                                withAnimation {
                                    scale = 1.0
                                    currentOffset = .zero
                                    temporaryOffset = .zero
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            //MARK: - HEADER (toolbar) for chat view
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                getBackground()
            }
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        if authViewModel.destination == nil {
                            dismiss()
                        } else {
                            authViewModel.destination = nil
                            showMessage = false
                        }
                    } label: {
                        Label("Back", systemImage: "chevron.backward")
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Button {
                        showProfile = true
                    } label: {
                        Text("\(user.first_name) \(user.last_name)")
                            .font(.headline) // Styling to imitate navigationTitle
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showChangeTheme = true
                        } label: {
                            Label("Change theme", systemImage: "paintbrush")
                        }
                        
                        if let u = authViewModel.currentUser, !u.blockedUsers.contains(user.id) {
                            // Если пользователь не заблокирован
                            Button {
                                authViewModel.currentUser?.blockedUsers.append(user.id)
                                syncAddFire(blockedUserID: user.id)
                                showSafari = true
                            } label: {
                                Label("Report & block", systemImage: "exclamationmark.shield")
                            }
                        }
                        
                        if let blockedUsers = authViewModel.currentUser?.blockedUsers, blockedUsers.contains(user.id) {
                            // Если пользователь заблокирован
                            if let index = blockedUsers.firstIndex(of: user.id) {
                                Button {
                                    authViewModel.currentUser?.blockedUsers.remove(at: index)
                                    syncDelFire(blockedUserID: user.id)
                                } label: {
                                    Label("Unblock user", systemImage: "person")
                                }
                            }
                        } else {
                            // Если пользователь не заблокирован
                            Button {
                                authViewModel.currentUser?.blockedUsers.append(user.id)
                                syncAddFire(blockedUserID: user.id)
                            } label: {
                                Label("Block user", systemImage: "person.slash")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showSafari) {
                SafariView(url: URL(string: "https://skillify.space/contact/?f_name=\(authViewModel.currentUser?.first_name ?? "")&nickname=\(authViewModel.currentUser?.nickname ?? "")&subject=Report+user")!)
            }
            .sheet(isPresented: $showProfile, onDismiss: {
                showProfile = false
            }, content: {
                ProfileView(showProfile: $showProfile, user: user)
            })
            .sheet(isPresented: $showChangeTheme, onDismiss: {
                getBackground()
            }) {
                ChangeThemeView(userId: userId)
                    .presentationDetents([.height(200)])
            }
        }
    } // var body
    
    func getBackground() {
        print("here background")
        if let th = UserDefaults.standard.string(forKey: "chatTheme\(userId)") {
            withAnimation {
                self.theme = th
            }
        }
    }
    
    func uploadFile(url: URL) async {
        let fileName = url.lastPathComponent
        let ref = Storage.storage().reference().child("iosUsers/\(authViewModel.currentUser?.id ?? "default")/\(fileName)")
        let metadata = StorageMetadata()
        metadata.contentType = "application/octet-stream"
        
        do {
            let _ = try await ref.putFileAsync(from: url, metadata: metadata)
            let downloadURL = try await ref.downloadURL()
            DispatchQueue.main.async {
                self.sendMessage(imageUrl: downloadURL.absoluteString)
            }
        } catch {
            print("Ошибка загрузки файла: \(error)")
        }
    }
    
    func syncAddFire (blockedUserID: String) {
        guard let uid = authViewModel.currentUser?.id else { return }
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(uid)
        
        userRef.updateData([
            "blockedUsers": FieldValue.arrayUnion([blockedUserID])
        ]) { error in
            if let error = error {
                print("Error updating user: \(error)")
            } else {
                print("User successfully updated")
            }
        }
    }
    
    func syncDelFire (blockedUserID: String) {
        guard let uid = authViewModel.currentUser?.id else { return }
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(uid)
        
        userRef.updateData([
            "blockedUsers": FieldValue.arrayRemove([blockedUserID])
        ]) { error in
            if let error = error {
                print("Error updating user: \(error)")
            } else {
                print("User successfully updated")
            }
        }
    }
    
    func onChangeTask() async {
        if let photoPickerItem,
           let data = try? await photoPickerItem.loadTransferable(type: Data.self) {
            // Create a reference to the file you want to upload
            print(photoPickerItem.supportedContentTypes)
            messagesList.append(Chat(id: "default-loader-placeholder", cUid: authViewModel.currentUser!.id, mediaUrl: "0", time: Date().timeIntervalSince1970, status: "u"))
            var string: String
            if photoPickerItem.supportedContentTypes.first == .movie ||
                photoPickerItem.supportedContentTypes.first == .mpeg4Movie ||
                photoPickerItem.supportedContentTypes.first == .quickTimeMovie {
                string = "iosUsers/\(authViewModel.currentUser?.id ?? "default")/\(UUID().uuidString).mp4"
            } else {
                string = "iosUsers/\(authViewModel.currentUser?.id ?? "default")/\(UUID().uuidString).jpg"
            }
            let ref = Storage.storage().reference().child(string)
            // Upload the file to the path "images/rivers.jpg"
            _ = ref.putData(data, metadata: nil) { (metadata, error) in
                guard let metadata = metadata else {
                    return
                }
                // Metadata contains file metadata such as size, content-type.
                _ = metadata.size
                // You can also access to download URL after upload.
                ref.downloadURL { (url, error) in
                    guard let downloadURL = url else {
                        return
                    }
                    sendMessage(imageUrl: downloadURL.absoluteString)
                }
            }
        }
    }
    
    var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                scale = max(1.0, value.magnitude)
            }
    }
    
    var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                currentOffset = CGSize(width: value.translation.width + temporaryOffset.width, height: value.translation.height + temporaryOffset.height)
            }
            .onEnded { value in
                temporaryOffset = currentOffset
            }
    }
    
    func loadSaveMessage() {
        self.userId = "\(authViewModel.currentUser!.id)\(user.id)"
        let message = Message(
            id: userId,
            lastData: ["you: ", "Chat created", "status"],
            messages: [],
            time: Date().timeIntervalSince1970,
            uids: [authViewModel.currentUser!.id, user.id])
        var chat: Chat
        if let reply = replyMessage {
            print("optional here")
            chat = Chat(
                id: UUID().uuidString,
                cUid: authViewModel.currentUser!.id,
                text: messageText,
                mediaUrl: nil,
                time: Date().timeIntervalSince1970,
                replyTo: [String(reply.text!/*.prefix(8)*/), reply.id]
            )
            replyMessage = nil
        } else {
            chat = Chat(
                id: UUID().uuidString,
                cUid: authViewModel.currentUser!.id,
                text: messageText,
                mediaUrl: nil,
                time: Date().timeIntervalSince1970)
        }
        let userRef = Firestore.firestore().collection("messages").document(userId)
        authViewModel.currentUser!.messages.append([user.id: self.userId])
        Task {
            do {
                let encodedUser = try Firestore.Encoder().encode(message)
                try await userRef.setData(encodedUser)
                authViewModel.updateUsersAFirebase(
                    str: "messages",
                    newStr: [user.id: userId],
                    cUid: authViewModel.currentUser!.id)
                authViewModel.updateUsersAFirebase(
                    str: "messages",
                    newStr: [authViewModel.currentUser!.id: userId],
                    cUid: user.id)
                authViewModel.updateMessageFirebase(
                    str: "messages",
                    newChat: chat,
                    cUid: userId)
                
                messagesList.append(chat)
                updateStatusInMessages()
                //send notification
                await authViewModel.sendNotification(
                    header: "First message from \(authViewModel.currentUser?.first_name ?? "User")",
                    playerId: user.id,
                    messageText: messageText,
                    targetText: userId,
                    type: .message,
                    privacy: user.privacyData) {
                        messageText = ""
                    }
            } catch {
                // Обработка ошибки
                print("Ошибка при кодировании или установке данных: \(error)")
            }
        }
    }
    
    func sendMessage(imageUrl: String?) {
        var chat: Chat
        if let imageUrl {
            chat = Chat(
                id: UUID().uuidString,
                cUid: authViewModel.currentUser!.id,
                text: nil,
                mediaUrl: imageUrl,
                time: Date().timeIntervalSince1970
            )
            UserDefaults.standard.set("🌄 attachment", forKey: userId)
        } else if let reply = replyMessage {
            chat = Chat(
                id: UUID().uuidString,
                cUid: authViewModel.currentUser!.id,
                text: messageText,
                mediaUrl: nil,
                time: Date().timeIntervalSince1970,
                replyTo: [String(reply.text/*.prefix(8)*/ ?? "🌄 attachment"), reply.id]
            )
            UserDefaults.standard.set(messageText, forKey: userId)
            replyMessage = nil
        } else {
            chat = Chat(
                id: UUID().uuidString,
                cUid: authViewModel.currentUser!.id,
                text: messageText,
                mediaUrl: nil,
                time: Date().timeIntervalSince1970)
            UserDefaults.standard.set(messageText, forKey: userId)
        }
        
        Task {
            authViewModel.updateMessageFirebase(
                str: "messages",
                newChat: chat,
                cUid: userId)
            
            messagesList.append(chat)
            if let _ = photoPickerItem {
                let index = messagesList.firstIndex(where: { $0.id == "default-loader-placeholder" })
                if let index {
                    messagesList.remove(at: index)
                }
                photoPickerItem = nil
            }
            updateStatusInMessages()
            //send notification
            await authViewModel.sendNotification(
                header: "New message from \(authViewModel.currentUser?.first_name ?? "User")",
                playerId: user.id,
                messageText: messageText == "" ? "🌄 attachment" : messageText,
                targetText: userId,
                type: .message,
                privacy: user.privacyData) {
                    messageText = ""
                }
        }
    }
    
    func startListeningForMessages() {
        guard userId != "nil" else { return }
        
        Firestore.firestore().collection("admin").document("system").getDocument { (document, error) in
            if let document = document, document.exists {
                systemMessage = document.get("showMessagesAlert") as? String
            } else {
                print("error while loading admin doc: \(error?.localizedDescription ?? "No error description")")
            }
        }
        
        var listener: ListenerRegistration?
        
        // Удаляем предыдущий слушатель, если он существует
        listener?.remove()
        
        let db = Firestore.firestore()
        let docRef = db.collection("messages").document(userId)
        
        listener = docRef.addSnapshotListener { documentSnapshot, error in
            guard let document = documentSnapshot else {
                print("Ошибка получения документа: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            guard document.exists else {
                print("Документ не найден")
                messagesList.removeAll()
                return
            }
            
            do {
                let messageData = try document.data(as: Message.self)
                guard let fetchedMessages = messageData.messages else {
                    print("Нет сообщений для обработки.")
                    return
                }
                
                // Синхронизация сообщений
                synchronizeMessages(with: fetchedMessages)
            } catch {
                print("Ошибка декодирования сообщений: \(error)")
            }
        }
    }
    
    func synchronizeMessages(with fetchedMessages: [Chat]) {
        // Создаем временный массив для хранения актуального состояния сообщений
        var tempMessagesList = messagesList
        
        // Добавляем или обновляем сообщения
        for fetchedMessage in fetchedMessages {
            if let index = tempMessagesList.firstIndex(where: { $0.id == fetchedMessage.id }) {
                tempMessagesList[index] = fetchedMessage
            } else {
                tempMessagesList.append(fetchedMessage)
            }
        }
        
        // Удаляем сообщения, которых нет в полученном списке
        tempMessagesList = tempMessagesList.filter { message in
            fetchedMessages.contains(where: { $0.id == message.id })
        }
        
        // Обновляем основной список сообщений
        messagesList = tempMessagesList
    }
    
    func updateStatusInMessages() {
        let db = Firestore.firestore()
        let documentRef = db.collection("messages").document(userId)
        
        documentRef.getDocument { (document, error) in
            if let document = document, document.exists {
                if var messages = document.data()?["messages"] as? [[String: Any]] {
                    var isUpdated = false
                    for index in 0..<messages.count {
                        if let status = messages[index]["status"] as? String, status != "r",
                           let cUid = messages[index]["cUid"] as? String, cUid != authViewModel.currentUser!.id {
                            messages[index]["status"] = "r"
                            mViewModel.countUnread -= 1
                            isUpdated = true
                        }
                    }
                    
                    if isUpdated {
                        documentRef.updateData(["messages": messages]) { err in
                            if let err = err {
                                print("Ошибка при обновлении документа: \(err)")
                            } else {
                                print("Документ успешно обновлен")
                            }
                        }
                    }
                }
                if let sn = try? document.data(as: Message.self) {
                    if sn.lastData[0] != authViewModel.currentUser!.id {
                        documentRef.updateData([
                            "lastData": [sn.lastData[0], sn.lastData[1], "r"]
                        ]) { error in
                            if let error = error {
                                print("Error updating user: \(error)")
                            } else {
                                print("Chat successfully updated")
                            }
                        }
                    }
                }
            } else {
                print("Документ не найден или произошла ошибка в update: \(error?.localizedDescription ?? "Неизвестная ошибка")")
            }
        }
    }
    
    func updateMessage(messageId: String, text: String) {
        let db = Firestore.firestore()
        let documentRef = db.collection("messages").document(userId)
        
        documentRef.getDocument { (document, error) in
            if let document = document, document.exists {
                if var messages = document.data()?["messages"] as? [[String: Any]] {
                    if let index = messages.firstIndex(where: { $0["id"] as? String == messageId }) {
                        messages[index]["text"] = text
                        
                        documentRef.updateData(["messages": messages]) { err in
                            if let err = err {
                                print("Error updating document: \(err)")
                            } else {
                                print("Document successfully updated")
                            }
                        }
                        //                        UserDefaults.standard.set(text, forKey: userId)
                        // Check if the message is the last in the list
                        if index == messages.count - 1 {
                            documentRef.updateData(["lastData" : ["\(authViewModel.currentUser!.id)", "\(text)"]])
                        }
                    }
                }
            } else {
                print("Document not found or an error occurred: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
}

struct ImageVideoPicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    @Binding var messagesList: [Chat] // Предполагается, что это ваша структура данных
    var authViewModel: AuthViewModel // Предполагается, что у вас есть экземпляр ViewModel для аутентификации
    var sendMessage: (String) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.mediaTypes = ["public.image", "public.movie"] // Разрешаем выбор изображений и видео
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: ImageVideoPicker
        
        init(_ parent: ImageVideoPicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            picker.dismiss(animated: true) {
                // Обработка выбранного файла
                if let url = info[.mediaURL] as? URL {
                    // Обработка видео файла
                    Task {
                        await self.parent.uploadMedia(url, isVideo: true)
                    }
                } else if let image = info[.originalImage] as? UIImage, let data = image.jpegData(compressionQuality: 0.8) {
                    // Обработка изображения
                    Task {
                        await self.parent.uploadMedia(data, isVideo: false)
                    }
                }
            }
        }
    }
    
    //MARK: - Загрузка медиа
    private func uploadMedia(_ data: Data, isVideo: Bool) async {
        let fileName = isVideo ? "media/\(UUID().uuidString).mp4" : "iosUsers/\(authViewModel.currentUser?.id ?? "default")/\(UUID().uuidString).jpg"
        let ref = Storage.storage().reference().child(fileName)
        let metadata = StorageMetadata()
        metadata.contentType = isVideo ? "video/mp4" : "image/jpeg"
        
        do {
            let _ = try await ref.putDataAsync(data, metadata: metadata)
            let downloadURL = try await ref.downloadURL()
            self.sendMessage(downloadURL.absoluteString)
        } catch {
            print(error)
        }
    }
    
    // Перегрузка для поддержки URL (видео)
    private func uploadMedia(_ url: URL, isVideo: Bool) async {
        guard let data = try? Data(contentsOf: url) else { return }
        await uploadMedia(data, isVideo: isVideo)
    }
}

#Preview {
    ChatView(userId: "", showMessage: .constant(true), user: User(id: "", first_name: "Child", last_name: "red", email: "mail", nickname: "oil", phone: "", birthday: Date()))
        .environmentObject(AuthViewModel.mock)
        .environmentObject(CallManager.mock)
        .environmentObject(MessagesViewModel.mock)
}

struct PlaceholderTextEditor: View {
    var placeholder: String
    @Binding var text: String
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
            }
            TextEditor(text: $text)
                .opacity(text.isEmpty ? 0.5 : 1)
        }
    }
}

struct ChatItemView: View {
    var message: Chat
    var user: User
    var userId: String
    @EnvironmentObject var viewModel: AuthViewModel
    @Binding var replyMessage: Chat?
    @Binding var editMessage: Chat?
    @Binding var messageText: String
    @Binding var messagesList: [Chat]
    @Binding var scrollTo: String
    @Binding var bigImage: String?
    @State private var isShowingVideoPlayer = false
    @State private var image: UIImage? = .placeholder
    @State private var isLoading = false
    
    //    @State private var isShowingDocumentPicker = false
    @State private var documentInteractionController: UIDocumentInteractionController?
    @State private var coordinator: Coordinator?
    @State private var score: Double = 0.0
    @State private var emotions: Double = 0.0
    
    var body: some View {
        HStack {
            if message.cUid != user.id { // наше сообщение
                Spacer()
                messageBubble(text: message.text, isCurrentUser: false)
            } else {
                messageBubble(text: message.text, isCurrentUser: true)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity) // Растягиваем HStack на всю доступную ширину
        .padding(.bottom, 5)
        .onAppear {
            if let txt = message.text {
                analyzeText(inputText: txt) { res, res2 in
                    score = res
                    emotions = res2
                }
            } else if let img = message.mediaUrl {
                analyzeImage(imageURL: URL(string: img) ?? URL(string: "https://example.com")!) { res in
                    score = res
                }
            }
        }
    }
    
    @ViewBuilder
    private func messageBubble(text: String?, isCurrentUser: Bool) -> some View {
        VStack (alignment: isCurrentUser ? .leading : .trailing) {
            if let reply = message.replyTo {
                Text("Replied to \(reply[0])")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: isCurrentUser ? .leading : .trailing)
            }
            
            // main part
            if let img = message.mediaUrl {
                if isVideoURL(img) {
                    Image(uiImage: image!)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 300)
                        .cornerRadius(15)
                        .onAppear { loadThumbnail(url: URL(string: img)!) }
                        .onTapGesture {
                            isShowingVideoPlayer = true
                        }
                        .fullScreenCover(isPresented: $isShowingVideoPlayer) {
                            VStack(alignment: .trailing) {
                                Button {
                                    isShowingVideoPlayer = false
                                } label: {
                                    Image(systemName: "xmark")
                                        .resizable()
                                        .foregroundColor(.white)
                                        .frame(width: 15, height: 15)
                                }
                                .padding(.horizontal)
                                if let videoURL = URL(string: img) {
                                    VideoPlayer(player: AVPlayer(url: videoURL))
                                        .edgesIgnoringSafeArea(.all) // Игнорируем safe area для полноэкранного режима
                                        .onAppear(perform: {
                                            AVPlayer(url: videoURL).play()
                                        })
                                }
                            }
                            .background(.black)
                        }
                } else if let url = URL(string: img) {
                    if isImageURL(url) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Image("placeholder")
                                .resizable()
                        }
                        .frame(width: 200, height: 200)
                        .cornerRadius(15)
                        .onTapGesture {
                            bigImage = img
                        }
                    } else {
                        //MARK: - FILE VIEW
                        if isLoading {
                            ProgressView()
                        } else {
                            Label("File", systemImage: "doc.text")
                                .onTapGesture {
                                    isLoading = true
                                    downloadFile(from: url) { localURL in
                                        if let localURL = localURL {
                                            presentDocumentInteractionController(url: localURL)
                                        } else {
                                            print("Failed to download file.")
                                        }
                                        isLoading = false
                                    }
                                }
                        }
                    }
                } else {
                    Image("placeholder")
                        .resizable()
                        .frame(width: 200, height: 200)
                }
            } else if let txt = text {
                Text(txt)
            } else {
                Label(isCurrentUser ? "Incoming Call" : "Outgoing call", systemImage: "phone.connection")
            }
            // end of main part
            
            //MARK: - Violant message
            if score < -0.8 || emotions < -0.8 {
                Label("Maybe violant content", systemImage: "exclamationmark.circle")
                    .font(.caption2)
                    .foregroundStyle(.red)
            }
            
            if isCurrentUser {
                HStack {
                    Text(timeString(from: message.time))
                        .padding(.top, 2)
                        .font(.caption2)
                    
                    if let e = message.emoji {
                        Text(e)
                            .padding(.top, 2)
                            .font(.caption2)
                    }
                }
            } else {
                HStack {
                    if let e = message.emoji {
                        Text(e)
                            .font(.caption2)
                            .padding(.top, 2)
                    }
                    
                    Text(timeString(from: message.time))
                        .padding(.top, 2)
                        .font(.caption2)
                    
                    if message.status == "r" {
                        Image("read-2")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 15, height: 15)
                            .padding(0)
                    } else {
                        Image(systemName: "checkmark")
                            .resizable()
                            .frame(width: 10, height: 10)
                    }
                }
            }
        }
        .padding()
        .contextMenu {
            Divider()
            
            Button {
                editMessage = nil
                replyMessage = message
            } label: {
                Label("Reply", systemImage: "arrowshape.turn.up.left")
            }
            if let text = message.text {
                Button {
                    UIPasteboard.general.string = text
                } label: {
                    Label("Copy message", systemImage: "doc.on.doc")
                }
            }
            if viewModel.currentUser!.id == message.cUid {
                if let text = message.text {
                    Button {
                        replyMessage = nil
                        editMessage = message
                        messageText = text
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                }
                Button {
                    deleteMessage(messageId: message.cUid, mId: message.id)
                    let index = messagesList.firstIndex(where: { $0.id == message.id })
                    if let ind = index {
                        messagesList.remove(at: ind)
                    }
                } label: {
                    Label("Delete", image: "bin")
                }
                
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button {
                replyMessage = message
            } label: {
                Label("Reply", systemImage: "arrowshape.turn.up.left")
            }
        }
        .background(isCurrentUser ? Color.white : Color.blue)
        .foregroundColor(isCurrentUser ? .black : .white)
        .cornerRadius(15)
        .frame(minWidth: 100, maxWidth: 250, alignment: isCurrentUser ? .leading : .trailing)
        .fixedSize(horizontal: false, vertical: true)// Это позволяет тексту определять размер вьюё
        .onTapGesture {
            if let reply = message.replyTo {
                scrollTo = reply[1]
            }
        }
    }
    
    func analyzeImage(imageURL: URL, completion: @escaping (Double) -> Void) {
        URLSession.shared.dataTask(with: imageURL) { data, response, error in
            if let error = error {
                print("Error downloading image: \(error.localizedDescription)")
                completion(1.0) // Assume inappropriate content if there's an error
                return
            }
            
            guard let data = data, let image = UIImage(data: data) else {
                print("Failed to load image from URL")
                completion(1.0) // Assume inappropriate content if image load fails
                return
            }
            
            self.sendImageToAPI(image: image, completion: completion)
        }.resume()
    }
    
    func sendImageToAPI(image: UIImage, completion: @escaping (Double) -> Void) {
        let apiKey = "AIzaSyBSJ8O0pLR9Ve7S6zX2zA0kqb4wi2LMY6Q"
        let url = URL(string: "https://vision.googleapis.com/v1/images:annotate?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let base64Image = image.jpegData(compressionQuality: 1.0)?.base64EncodedString() ?? ""
        let requestJson: [String: Any] = [
            "requests": [
                [
                    "image": ["content": base64Image],
                    "features": [["type": "SAFE_SEARCH_DETECTION"]]
                ]
            ]
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: requestJson, options: []) else {
            completion(1.0) // Assume inappropriate content if JSON serialization fails
            return
        }
        request.httpBody = httpBody
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error making request: \(error.localizedDescription)")
                completion(1.0) // Assume inappropriate content if request fails
                return
            }
            
            guard let data = data else {
                print("No data received")
                completion(1.0) // Assume inappropriate content if no data is received
                return
            }
            
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let responses = jsonResponse["responses"] as? [[String: Any]],
                   let safeSearchAnnotation = responses.first?["safeSearchAnnotation"] as? [String: Any] {
                    DispatchQueue.main.async {
                        self.handleSafeSearchAnnotation(safeSearchAnnotation, completion: completion)
                    }
                } else {
                    print("SafeSearch annotation not found in the response")
                    completion(1.0) // Assume inappropriate content if annotation is not found
                }
            } catch {
                print("Error parsing JSON: \(error.localizedDescription)")
                completion(1.0) // Assume inappropriate content if JSON parsing fails
            }
        }.resume()
    }
    
    func handleSafeSearchAnnotation(_ annotation: [String: Any], completion: @escaping (Double) -> Void) {
        let adult = annotation["adult"] as? String ?? "UNKNOWN"
        let racy = annotation["racy"] as? String ?? "UNKNOWN"
        let violence = annotation["violence"] as? String ?? "UNKNOWN"
        
        print(adult)
        print(racy)
        print(violence)
        
        if adult == "LIKELY" || adult == "VERY_LIKELY" || racy == "LIKELY" || racy == "VERY_LIKELY" || violence == "LIKELY" || violence == "VERY_LIKELY" {
            completion(-1.0) // Return 1.0 for inappropriate content
        } else {
            completion(0.0) // Return 0.0 for appropriate content
        }
    }
    
    func analyzeText(inputText: String, completion: @escaping (Double, Double) -> Void) {
        let apiKey = "AIzaSyCFg3ZNewUl8B2jCRjYhWj90Zqi-DfAVtU"
        let url = URL(string: "https://language.googleapis.com/v2/documents:analyzeSentiment?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let document = [
            "document": [
                "type": "PLAIN_TEXT",
                "content": inputText
            ],
            "encodingType": "UTF8"
        ] as [String : Any]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: document, options: []) else {
            return
        }
        request.httpBody = httpBody
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                if let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let sentiment = jsonResponse["documentSentiment"] as? [String: Any],
                   let score = sentiment["score"] as? Double,
                   let magnitude = sentiment["magnitude"] as? Double {
                    DispatchQueue.main.async {
                        completion(score, magnitude)
                    }
                }
            }
        }.resume()
    }
    
    var emojiReactions: [String] {
        return ["👍"]
    }
    
    func presentDocumentInteractionController(url: URL) {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: url.path) {
            let controller = UIDocumentInteractionController(url: url)
            let coordinator = Coordinator(self) // Создайте экземпляр `Coordinator`
            self.coordinator = coordinator // Сохраните экземпляр `Coordinator`
            controller.delegate = coordinator // Назначьте координатор делегатом
            controller.presentPreview(animated: true)
            self.documentInteractionController = controller
        } else {
            print("File does not exist at \(url.path)")
        }
    }
    
    func downloadFile(from url: URL, completion: @escaping (URL?) -> Void) {
        let storageRef = Storage.storage().reference(forURL: url.absoluteString)
        let localURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
        
        _ = storageRef.write(toFile: localURL) { url, error in
            if let error = error {
                print("Error downloading file: \(error)")
                completion(nil)
            } else {
                completion(url)
            }
        }
        
        //        downloadTask.observe(.progress) { snapshot in
        //            // Отслеживание прогресса загрузки, если необходимо
        //        }
    }
    
    func loadThumbnail(url: URL) {
        let asset = AVAsset(url: url)
        let assetImageGenerator = AVAssetImageGenerator(asset: asset)
        assetImageGenerator.appliesPreferredTrackTransform = true
        assetImageGenerator.requestedTimeToleranceBefore = .zero
        assetImageGenerator.requestedTimeToleranceAfter = .zero
        
        let time = CMTime(seconds: 1, preferredTimescale: 600)
        assetImageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, image, _, _, _ in
            if let image = image {
                self.image = UIImage(cgImage: image)
            }
        }
    }
    
    func timeString(from timestamp: Double) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.timeStyle = .short // Краткий стиль времени
        
        // Проверяем, является ли дата сегодняшним днем
        if Calendar.current.isDateInToday(date) {
            formatter.dateStyle = .none // Не показываем дату
            return "Today, " + formatter.string(from: date)
        } else {
            formatter.dateStyle = .medium // Показываем дату в среднем формате
            return formatter.string(from: date)
        }
    }
    
    func isVideoURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let path = components.path as String? else { return false }
        
        // Извлекаем расширение файла из пути URL
        let pathExtension = (path as NSString).pathExtension.lowercased()
        
        // Предполагаемые форматы видео
        let videoFormats = ["mov", "mp4"]
        
        return videoFormats.contains(pathExtension)
    }
    
    func isImageURL(_ url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let path = components.path as String? else { return false }
        
        // Извлекаем расширение файла из пути URL
        let pathExtension = (path as NSString).pathExtension.lowercased()
        
        // Предполагаемые форматы видео
        let imageFormats = ["jpeg", "png", "jpg"]
        
        return imageFormats.contains(pathExtension)
    }
    
    func deleteChat() {
        let db = Firestore.firestore()
        let documentRef = db.collection("messages").document(userId)
        documentRef.delete { err in
            print("error")
        }
        let userDocRef = Firestore.firestore().collection("users").document(viewModel.currentUser!.id)
        userDocRef.getDocument { (document, error) in
            if let document = document, document.exists, let messages = document.data()?["messages"] as? [[String: Any]] {
                // Находим индекс элемента для удаления
                if let indexToRemove = messages.firstIndex(where: { $0.values.contains(where: { $0 as? String == userId }) }) {
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
    }
    
    func deleteMessage(messageId: String, mId: String) {
        let db = Firestore.firestore()
        let documentRef = db.collection("messages").document(userId)
        print("userId \(userId)")
        
        documentRef.getDocument { (document, error) in
            if let document = document, document.exists {
                if var messages = document.data()?["messages"] as? [[String: Any]] {
                    var isUpdated = false
                    if let index = messages.firstIndex(where: { $0["id"] as? String == mId }) {
                        if messages.count > 2 {
                            if index == messages.count - 1 && index > 1 {
                                documentRef.updateData(["lastData" : ["\(messages[index - 1]["cUid"] ?? userId)", "\(messages[index - 1]["text"] ?? "")", "u"]])
                            }
                        } else {
                            print("delete chating")
                            deleteChat()
                        }
                        
                        messages.remove(at: index)
                        isUpdated = true
                    }
                    
                    if isUpdated {
                        documentRef.updateData(["messages": messages]) { err in
                            if let err = err {
                                print("Ошибка при обновлении документа: \(err)")
                            } else {
                                print("Документ успешно обновлен")
                            }
                        }
                    }
                }
            } else {
                print("Документ не найден или произошла ошибка: \(error?.localizedDescription ?? "Неизвестная ошибка")")
            }
        }
    }
}

class Coordinator: NSObject, UIDocumentInteractionControllerDelegate {
    var parent: ChatItemView
    
    init(_ parent: ChatItemView) {
        self.parent = parent
    }
    
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return UIApplication.shared.windows.first?.rootViewController ?? UIViewController()
    }
}

struct SystemMessageView: View {
    var systemMessage: String
    
    var body: some View {
        HStack {
            Text(systemMessage)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color("warningColor").opacity(0.5))
                .cornerRadius(15)
                .padding()
        }
    }
}
