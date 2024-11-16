//
//  AuthViewModel.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 18.12.2023.
//

import Foundation
import SwiftUI
import Firebase
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import FirebaseFirestore
import AuthenticationServices
import OneSignalFramework
import RevenueCat

class AuthViewModel: ObservableObject {
    @Published var userState: UserState = .loading
    @Published var currentUser: User?
    @Published var errorMessage: String?
    @Published var users = [User]()
    
    @Published var destination: String? = nil
    @Published var selectedTab: TabType = .home
    
    init() {
        Task {
            await loadUser()
        }
    }
    
    func createUser(email: String, pass: String, completion: @escaping (String?) -> Void) async throws {
        if (email.isEmpty || pass.count < 6) {
            return
        }
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: pass)
            let user = User(id: result.user.uid, first_name: "", last_name: "", email: email, nickname: "", phone: "", birthday: Date())
            let encodedUser = try Firestore.Encoder().encode(user)
            try await Firestore.firestore().collection("users").document(user.id).setData(encodedUser)
            
            await loadUser()
            completion(nil)
        } catch {
            print("error")
            completion("error")
        }
    }
    
    func signInWithEmail(email: String, pass: String, completion: @escaping (String?) -> Void) async {
        do {
            let authResult = try await Auth.auth().signIn(withEmail: email, password: pass)
            OneSignal.login(authResult.user.uid)
            DispatchQueue.main.async { [weak self] in
                Task {
                    await self?.loadUser()
                }
                completion(nil)
            }
        } catch {
            DispatchQueue.main.async {
                print("Ошибка входа: \(error.localizedDescription)")
                completion(error.localizedDescription)
            }
        }
    }
    
    func signInWithGoogle(completion: @escaping (String?) -> Void) {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            completion("error")
            return
        }
        
        // Create Google Sign In configuration object.
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        // Start the sign in flow!
        if let rootVC = getRootViewController() {
            GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { [unowned self] result, error in
                guard error == nil else {
                    completion(error?.localizedDescription)
                    return
                }
                
                guard let user = result?.user,
                      let idToken = user.idToken?.tokenString
                else {
                    completion("error")
                    return
                }
                
                let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
                Auth.auth().signIn(with: credential) { [weak self] result, error in
                    DispatchQueue.main.async {
                        if let user = result?.user {
                            OneSignal.login(user.uid)
                            
                            var firstName: String = ""
                            var lastName: String = ""
                            
                            if let displayName = user.displayName {
                                let nameComponents = displayName.split(separator: " ")
                                if nameComponents.count > 0 {
                                    firstName = String(nameComponents[0])
                                }
                                if nameComponents.count > 1 {
                                    lastName = String(nameComponents[1])
                                }
                            }
                            
                            Task {
                                [weak self] in // Capture self as a weak reference
                                guard let strongSelf = self else {
                                    return
                                }
                                await strongSelf.registerUserAndLoadProfile(uid: user.uid, email: user.email ?? "", firstName: firstName, lastName: lastName, phone: "")
                            }
                            completion(nil)
                        }
                    }
                }
            }
        }
    }
    
    func updateSkill(_ skill: Skill) {
        if let index = currentUser!.selfSkills.firstIndex(where: { $0.name == skill.name }) {
            currentUser!.selfSkills[index] = skill
        } else {
            currentUser!.selfSkills.append(skill)
        }
        syncWithFirebase()
    }
    
    func updateLSkill(_ skill: Skill) {
        if let index = currentUser!.learningSkills.firstIndex(where: { $0.name == skill.name }) {
            currentUser!.learningSkills[index] = skill
        } else {
            currentUser!.learningSkills.append(skill)
        }
        syncWithFirebase()
    }
    
    func syncWithFirebase(){
        guard let uid = currentUser?.id else { return }
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(uid)
        
        userRef.updateData([
            "selfSkills": currentUser!.selfSkills.map { ["name": $0.name, "level": $0.level ?? ""] },
            "learningSkills": currentUser!.learningSkills.map { ["name": $0.name, "level": $0.level ?? ""] }
        ]) { error in
            if let error = error {
                print("Error updating user: \(error)")
            } else {
                print("User successfully updated")
            }
        }
    }
    
    func updateUsersFirebase(isAdd: Bool = true, str: String, newStr: String, cUid: String) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(cUid)
        
        userRef.updateData([
            str: isAdd ? FieldValue.arrayUnion([newStr]) : FieldValue.arrayRemove([newStr])
        ]) { error in
            if let error = error {
                print("Error updating user: \(error)")
            } else {
                print("User successfully updated 1")
            }
        }
    }
    
    func fetchAllUsers() {
        guard let _ = self.currentUser else { return }
        
        Firestore.firestore().collection("users")
            .getDocuments { [weak self] (querySnapshot, error) in
                guard let documents = querySnapshot?.documents else {
                    print("No documents: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                let allUsers = documents.compactMap { queryDocumentSnapshot -> User? in
                    try? queryDocumentSnapshot.data(as: User.self)
                }
                
                self?.users = allUsers.filter({$0.id != self!.currentUser!.id && UserHelper.isUserPro($0.proDate) && !self!.currentUser!.blockedUsers.contains($0.id)})
            }
    }
    
    func updateUsersIntFirebase(isAdd: Bool = true, str: String, newStr: Double, cUid: String) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(cUid)
        
        userRef.updateData([
            str: isAdd ? newStr : 0
        ]) { error in
            if let error = error {
                print("Error updating user: \(error)")
            } else {
                print("User successfully updated 2")
            }
        }
    }
    
    func updateUsersAFirebase(isAdd: Bool = true, str: String, newStr: [String: String], cUid: String) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(cUid)
        
        userRef.updateData([
            str: isAdd ? FieldValue.arrayUnion([newStr]) : FieldValue.arrayRemove([newStr])
        ]) { error in
            if let error = error {
                print("Error updating user: \(error)")
            } else {
                print("User successfully updated 3")
            }
        }
    }
    
    func updateDataFirebase(isAdd: Bool = true, str: String, newData: Favorite) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(currentUser!.id)
        
        do {
            // Сериализация объекта Chat в словарь
            let chatData = try JSONEncoder().encode(newData)
            guard let chatDictionary = try JSONSerialization.jsonObject(with: chatData, options: []) as? [String: Any] else {
                print("Ошибка при сериализации объекта Chat")
                return
            }
            
            userRef.updateData([
                str: isAdd ? FieldValue.arrayUnion([chatDictionary]) : FieldValue.arrayRemove([chatDictionary])
            ]) { error in
                if let error = error {
                    print("Error updating user: \(error)")
                } else {
                    print("Chat successfully updated")
                }
            }
        } catch {
            print("Error serializing chat object: \(error)")
        }
    }
    
    func isNicknameUnique(_ nickname: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        let usersRef = db.collection("users")
        
        usersRef.whereField("nickname", isEqualTo: nickname).getDocuments { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
                completion(false)
            } else if querySnapshot!.documents.isEmpty {
                completion(true) // Nickname уникален
            } else if nickname == self.currentUser?.nickname {
                completion(true) // Nickname уникален
            } else {
                completion(false) // Nickname уже существует
            }
        }
    }
    
    func signInWithPhone(phoneNumber: String) {
        PhoneAuthProvider.provider()
            .verifyPhoneNumber(phoneNumber, uiDelegate: nil) { [weak self] verificationID, error in
                if let error = error {
                    // Обновляем свойство с сообщением об ошибке на главном потоке
                    DispatchQueue.main.async {
                        self?.errorMessage = error.localizedDescription
                    }
                    return
                }
                UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
            }
    }
    
    func loginViaPhoneFirebase(verificationCode: String, completion: @escaping (String?) -> Void) {
        guard let verificationID = UserDefaults.standard.string(forKey: "authVerificationID") else {
            self.errorMessage = "Verification ID not found"
            completion("Verification ID not found")
            return
        }
        
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: verificationCode
        )
        
        Auth.auth().signIn(with: credential) { [weak self] authResult, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(error.localizedDescription)
                } else {
                    DispatchQueue.main.async {
                        if let user = authResult?.user {
                            OneSignal.login(user.uid)
                            Task {
                                [weak self] in // Capture self as a weak reference
                                guard let strongSelf = self else {
                                    return
                                }
                                await strongSelf.registerUserAndLoadProfile(uid: user.uid, email: "", firstName: "", lastName: "", phone: user.phoneNumber ?? "")
                            }
                            completion(nil)
                        }
                    }
                }
            }
        }
    }
    
    func registerUserAndLoadProfile(uid: String, email: String, firstName: String, lastName: String, phone: String) async {
        DispatchQueue.main.async {
            self.userState = .loading
        }
        let userRef = Firestore.firestore().collection("users").document(uid)
        do {
            let documentSnapshot = try await userRef.getDocument()
            
            if documentSnapshot.data() != nil {} else {
                print("create a document")
                // Документ не существует, создаем новый документ.
                let newUser = User(id: uid, first_name: firstName, last_name: lastName, email: email, nickname: "", phone: phone, birthday: Date())
                DispatchQueue.main.async {
                    self.currentUser = newUser
                }
                let encodedUser = try Firestore.Encoder().encode(newUser)
                try await userRef.setData(encodedUser)
            }
            await loadUser() // Загрузка данных пользователя после регистрации или обнаружения существующего профиля.
        } catch {
            // Обработка возникших ошибок.
            print("Error in registerUserAndLoadProfile: \(error)")
        }
        DispatchQueue.main.async {
            self.userState = .loggedIn
        }
    }
    
    func getRootViewController() -> UIViewController? {
        // Attempt to find the root view controller of the current key window
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })?.rootViewController
    }
    
    func loadUser() async {
        // Установка состояния в .loading на основном потоке
        await MainActor.run {
            self.userState = .loading
        }

        guard let uid = Auth.auth().currentUser?.uid, !uid.isEmpty else {
            await MainActor.run {
                self.userState = .loggedOut
            }
            return
        }
        
        OneSignal.login(uid)

        do {
            let snapshot = try await Firestore.firestore().collection("users").document(uid).getDocument()
            
            if let currentUser = try? snapshot.data(as: User.self) {
                // Обновляем currentUser и userState на основном потоке
                await MainActor.run {
                    self.currentUser = currentUser
                    if currentUser.nickname.isEmpty {
                        self.userState = .profileEditRequired
                    } else if currentUser.block != nil {
                        self.userState = .blocked(reason: currentUser.block)
                    } else {
                        self.userState = .loggedIn
                    }
                }

                // Дополнительные асинхронные задачи
                Task {
                    await onlineMode()
                    checkPro()
//                    addUserListener(userId: uid)
                    fetchAllUsers()
                }
            } else {
                // Если документ не найден или не удалось загрузить данные пользователя
                await MainActor.run {
                    self.userState = .loggedOut
                }
            }
        } catch {
            // В случае ошибки установки состояния в .loggedOut
            await MainActor.run {
                self.userState = .loggedOut
            }
        }
    }
    
    func checkPro() {
        print("check pro")
        Purchases.shared.getCustomerInfo { info, error in
            if info?.entitlements.all["pro"]?.isActive == false {
                print("no subscription")
                self.cancelPro()
            }
        }
    }
    
    func offlineMode() async {
        guard let id = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(id)
        
        do {
            try await userRef.updateData([
                "online": false
            ])
            print("User successfully updated")
        } catch {
            print("Error updating user: \(error)")
        }
    }

    func onlineMode() async {
        guard let id = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(id)
        
        do {
            try await userRef.updateData([
                "online": true,
                "lastData": ["ios", UserHelper.getStringDate(), UserHelper.getAppVersion()]
            ])
            print("User successfully updated")
        } catch {
            print("Error updating user: \(error)")
        }
    }
    
    func signOut() {
        let firebaseAuth = Auth.auth()
        UserDefaults.standard.removeObject(forKey: "nameUser")
        do {
            try firebaseAuth.signOut()
            OneSignal.logout()
            clearUserDefaults()
            userState = .loggedOut
            self.currentUser = nil
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
    
    func blockUser(userId: String) {
        guard let uid = currentUser?.id else { return }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(uid)
        
        userRef.updateData([
            "blockedUsers": FieldValue.arrayUnion([userId])
        ]) { error in
            if let error = error {
                print("Error updating user: \(error)")
            } else {
                print("User successfully updated")
                self.currentUser?.blockedUsers.append(userId)
            }
        }
    }
    
    func unblockUser(userId: String) {
        guard let uid = currentUser?.id else { return }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(uid)
        
        userRef.updateData([
            "blockedUsers": FieldValue.arrayRemove([userId])
        ]) { error in
            if let error = error {
                print("Error updating user: \(error)")
            } else {
                print("User successfully updated")
                self.currentUser?.blockedUsers.removeAll(where: { $0 == userId })
            }
        }
    }
    
    func clearUserDefaults() {
        if let appDomain = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: appDomain)
            UserDefaults.standard.synchronize()
        }
    }
    
//    func addUserListener(userId: String) {
//        let db = Firestore.firestore()
//        let docRef = db.collection("users").document(userId)
//        
//        docRef.addSnapshotListener { documentSnapshot, error in
//            guard let document = documentSnapshot else {
//                print("Error fetching document: \(error!)")
//                return
//            }
//            guard let data = document.data() else {
//                print("Document data was empty.")
//                return
//            }
//            self.updateUserModel(with: data)
//        }
//    }
//    
//    func updateUserModel(with data: [String: Any]) {
//        guard (Auth.auth().currentUser != nil) else { return }
//        
//        if let newName = data["first_name"] as? String, newName != currentUser?.first_name {
//            currentUser?.first_name = newName
//        }
//        if let newName = data["last_name"] as? String, newName != currentUser?.last_name {
//            currentUser?.last_name = newName
//        }
//        if let newName = data["bio"] as? String, newName != currentUser?.bio {
//            currentUser?.bio = newName
//        }
//        if let newName = data["language"] as? String, newName != currentUser?.language {
//            currentUser?.language = newName
//        }
//        if let newName = data["block"] as? String?, newName != currentUser?.block {
//            currentUser?.block = newName
//        }
//        if let newName = data["nickname"] as? String, newName != currentUser?.nickname {
//            currentUser?.nickname = newName
//        }
//        if let newName = data["urlAvatar"] as? String, newName != currentUser?.urlAvatar {
//            currentUser?.urlAvatar = newName
//        }
//        if let newName = data["sex"] as? String, newName != currentUser?.sex {
//            currentUser?.sex = newName
//        }
//        if let newName = data["online"] as? Bool, newName != currentUser?.online {
//            currentUser?.online = newName
//        }
//        if let newName = data["birthday"] as? Date, newName != currentUser?.birthday {
//            currentUser?.birthday = newName
//        }
//        if let newName = data["pro"] as? Double, newName != currentUser?.pro {
//            currentUser?.pro = newName
//        }
//        if let newName = data["calls"] as? [[String: String]], newName != currentUser?.calls {
//            currentUser?.calls = newName
//        }
//        if let newName = data["learningSkills"] as? [Skill], newName != currentUser?.learningSkills {
//            currentUser?.learningSkills = newName
//        }
//        if let newName = data["favorites"] as? [Favorite], newName != currentUser?.favorites {
//            currentUser?.favorites = newName
//        }
//        if let newName = data["selfSkills"] as? [Skill], newName != currentUser?.selfSkills {
//            currentUser?.selfSkills = newName
//        }
//        if let newName = data["blockedUsers"] as? [String], newName != currentUser?.blockedUsers {
//            currentUser?.blockedUsers = newName
//        }
//        if let newName = data["proData"] as? [String], newName != currentUser?.proData {
//            currentUser?.proData = newName
//        }
//        if let newName = data["privacyData"] as? [String], newName != currentUser?.privacyData {
//            currentUser?.privacyData = newName
//        }
//        if let newName = data["tags"] as? [String], newName != currentUser?.tags {
//            currentUser?.tags = newName
//        }
//        if let newName = data["notifications"] as? [String], newName != currentUser?.notifications {
//            currentUser?.notifications = newName
//        }
//        if let newName = data["subscribers"] as? [String], newName != currentUser?.subscribers {
//            currentUser?.subscribers = newName
//        }
//        if let newName = data["subscriptions"] as? [String], newName != currentUser?.subscriptions {
//            currentUser?.subscriptions = newName
//        }
//    }
    
    // тут все правильно реализовано. privacy - это массив privacyData у пользователя
    func sendNotification(header: String = "Skillify", playerId: String, messageText: String, targetText: String = "", type: NotificationType = .system, privacy: [String]? = nil, completion: () -> Void = {}) async {
        
        if let currentUser {
            let defaultAvatarURL = "https://firebasestorage.googleapis.com/v0/b/skillify-loviagin.appspot.com/o/user.png?alt=media&token=f655cfc6-c506-4417-a11a-6ee1c47a0371"
            
            if privacy == nil {
                senderNotifications(
                    header: header,
                    playerId: playerId,
                    messageText: messageText,
                    avatarUrl: currentUser.urlAvatar.isEmpty ? defaultAvatarURL : currentUser.urlAvatar,
                    completion: completion)
            } else {
                switch type {
                case .subscription:
                    if let privacyData = privacy, !privacyData.contains(where: { $0 == "blockSubscriptionNotification" }) {
                        senderNotifications(
                            header: header,
                            playerId: playerId,
                            messageText: messageText,
                            targetText: "skillify://@\(targetText)",
                            avatarUrl: currentUser.urlAvatar.isEmpty ? defaultAvatarURL : currentUser.urlAvatar,
                            completion: completion)
                        
                        let notification = Notification(title: messageText, userId: playerId, type: .user, url: targetText)
                        
                        try? Firestore.firestore().collection("notifications").addDocument(from: notification) { error in
                            if let error { print(error) }
                        }
                    }
                case .message:
                    if let privacyData = privacy, !privacyData.contains(where: { $0 == "blockMessageNotification" }) {
                        senderNotifications(
                            header: header,
                            playerId: playerId,
                            messageText: messageText,
                            targetText: "skillify://m/\(targetText)",
                            avatarUrl: currentUser.urlAvatar.isEmpty ? defaultAvatarURL : currentUser.urlAvatar,
                            completion: completion)
                        
                        let notification = Notification(title: messageText, userId: playerId, type: .chat, url: targetText)
                        
                        try? Firestore.firestore().collection("notifications").addDocument(from: notification) { error in
                            if let error { print(error) }
                        }
                    }
                case .system:
                    if let privacyData = privacy, !privacyData.contains(where: { $0 == "blockSystemNotification" }) {
                        senderNotifications(
                            header: header,
                            playerId: playerId,
                            messageText: messageText,
                            avatarUrl: currentUser.urlAvatar.isEmpty ? defaultAvatarURL : currentUser.urlAvatar,
                            completion: completion)
                    }
                }
            }
        }
    }
    
    private func senderNotifications(header: String, playerId: String, messageText: String, targetText: String = "", avatarUrl: String, completion: () -> Void) {
        let headers = [
            "accept": "application/json",
            "Authorization": "Basic NjcwMjEwOWItY2ZjZS00YTY3LTgyZTUtNzkzOTQ4ZGEwNzcy",
            "content-type": "application/json"
        ]
        
        let parameters = [
            "include_external_user_ids": [playerId],
            "headings": ["en": header],
            "contents": ["en": "\(messageText)"],
            "app_id": "e57ccffe-08a9-4fa8-8a63-8c3b143d2efd",
            "large_icon": avatarUrl,
            "url": targetText
        ] as [String : Any]
        
        completion()
        
        let postData = try? JSONSerialization.data(withJSONObject: parameters, options: [])
        
        let request = NSMutableURLRequest(url: NSURL(string: "https://onesignal.com/api/v1/notifications")! as URL,
                                          cachePolicy: .useProtocolCachePolicy,
                                          timeoutInterval: 10.0)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = postData! as Data
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            if (error != nil) {
                print(error as Any)
            } else {
                _ = response as? HTTPURLResponse
            }
        })
        
        dataTask.resume()
        print("sent notification")
    }
    
    func setPro(_ option: ProOption) {
        print("setPro")
        if let user = currentUser {
            let time = Calendar.current.date(byAdding: .month, value: option == .month ? 1 : 12, to: Date()) ?? Date()
            
            var data: [String] {
                if let data = user.proData, !data.isEmpty {
                    return data
                } else {
                    let data = ["cover:1", "emoji:sparkles", "status:star.fill"]
                    currentUser!.proData = data
                    return data
                }
            }
            
            Firestore.firestore().collection("users").document(user.id).updateData([
                "proDate": Timestamp(date: time),
                "proData": data
            ])

            currentUser!.proDate = time
        }
    }

    func cancelPro() {
        print("cance;ed")
        if let user = currentUser {
            let time = Date()
            Firestore.firestore().collection("users").document(user.id).updateData([
                "proDate": Timestamp(date: time)
            ])
            
            currentUser!.proDate = time
        }
    }
}


enum NotificationType {
    case subscription, message, system
}

enum ProOption {
    case year
    case month
}

extension AuthViewModel {
    static var mock: AuthViewModel {
        let viewModel = AuthViewModel()
        viewModel.currentUser = User(id: "Support", first_name: "Elia", last_name: "Loviagin", email: "ilia@loviagin.com", nickname: "nick", phone: "+70909998876", birthday: Date())
        viewModel.currentUser?.proData = ["user", "cover:3"]
        viewModel.currentUser?.urlAvatar = "avatar2"
        viewModel.currentUser?.devices = ["f3498hervuhivuheiqidcjeq", "owivje9qfh9r8euqw9e"]
        return viewModel
    }
}

enum TabType {
    case home, chats, account, discovery
}
