//
//  ProfileView.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 19.12.2023.
//

import Foundation
import SwiftUI
import FirebaseFirestore

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var callManager: CallManager
    @EnvironmentObject private var mViewModel: MessagesViewModel
    @State var user: User // пользователь который отображается в профиле
    
    @State var isLoadingMessage = true // для лоадера на кнопке сообщений
    @State var isVisible: Bool = false // флаг для звонков (true на несколько секунд, если звонки запрещены)
    @State var showPhoneCall: Bool = false // переход на вью звонка
    @State private var showMenu = false // Состояние для отслеживания видимости меню

    @State private var selectedMenuItem: MenuItem? // выбранный элемент меню
    @State var subscribers = 0 // задается в onAppear
    @State var subscriptions = 0
    @State var currentId = "" // id нашего пользователя
    let shareProfileMenuItem = MenuItem(id: "Share")
    let reportProfileMenuItem = MenuItem(id: "Report")
    
    var body: some View {
        NavigationStack {
            if isUserBlocked(user: user) {
                Text("User was blocked by administration")
            } else {
                ScrollView {
                    VStack {
                        if UserHelper.isUserPro(user.pro), let proData = user.proData, proData.contains(where: { $0.hasPrefix("cover:") }) { // проверка что пользователь ПРО
                            ZStack {
                                //MARK: - фон профиля
                                Rectangle()
                                    .fill(LinearGradient(
                                        gradient: Gradient(colors:[
                                            UserHelper.getColor1(proData.first(where: { $0.hasPrefix("cover:") }) ?? "cover:1").opacity(0.4), // берем цвет один
                                            UserHelper.getColor2(proData.first(where: { $0.hasPrefix("cover:") }) ?? "cover:1").opacity(0.4) // берем цвет два
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .ignoresSafeArea()
                                
                                //MARK: - эмодзи на фон профиля
                                if let emoji = proData.first(where: { $0.hasPrefix("emoji:") }) {
                                    EmojiCoverView(emoji: .constant(emoji))
                                }
                                
                                VStack {
                                    //MARK: - аватарка
                                    AvatarView(avatarUrl: user.urlAvatar)
                                        .padding(.top, 70)
                                    
                                    //MARK: - Имя, Фамилия и Никнейм
                                    HStack(spacing: 5) {
                                        Text("\(user.first_name) \(user.last_name)")
                                            .font(.title)
                                            .lineLimit(1)
                                        if let data = user.tags, data.contains("verified") { // галочка для верифицированных
                                            Image("verify")
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 20, height: 20)
                                        } else if let data = user.tags, data.contains("admin") { // другая галочка для админов
                                            Image("gold")
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 20, height: 20)
                                        } else if UserHelper.isUserPro(user.pro), let data = user.proData, let status = data.first(where: { $0.hasPrefix("status:") }) { // эмодзи для прошек
                                            Image(systemName: String(status.split(separator: ":").last ?? Substring(status)))
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 20, height: 20)
                                                .foregroundColor(.brandBlue)
                                        }
                                    }
                                    
                                    Text("@\(user.nickname)")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .padding(.bottom, 10)
                                }
                            }
                        } else { // если не про
                            VStack {
                                //MARK: - аватарка для НЕ про
                                AvatarView(avatarUrl: user.urlAvatar)
                                    .padding(.top, 70)
                                
                                //MARK: - Имя, Фамилия и Никнейм
                                HStack(spacing: 5) {
                                    Text("\(user.first_name) \(user.last_name)")
                                        .font(.title)
                                    if let data = user.tags, data.contains("verified") {
                                        Image("verify")
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 20, height: 20)
                                    } else if let data = user.tags, data.contains("admin") {
                                        Image("gold")
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 20, height: 20)
                                    }
                                }
                                
                                Text("@\(user.nickname)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .padding(.bottom, 10)
                            }
                            .background(.linearGradient(colors: [.brandBlue.opacity(0.3), .redApp.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        }
                        
                        //MARK: - BIO PROFILE
                        if !user.bio.isEmpty {
                            Text(user.bio)
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.gray)
                                .padding(.top, 5)
                                .padding(.horizontal, 12)
                        }
                        
                        //MARK: - Плашка с подписками/подписчиками
                        HStack {
                            NavigationLink(destination: SubscribersView(selection: SubscribersViewModel.SubscribersCategory.subscribers, subscribers: user.subscribers, subscriptions: user.subscriptions).toolbar(.hidden, for: .tabBar)) {
                                VStack {
                                    Text("\(subscribers)")
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                    Text("Subscibers")
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                }
                                .padding()
                            }
                            
                            NavigationLink(destination: SubscribersView(selection: SubscribersViewModel.SubscribersCategory.subscription, subscribers: user.subscribers, subscriptions: user.subscriptions).toolbar(.hidden, for: .tabBar)) {
                                VStack {
                                    Text("\(subscriptions)")
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                    Text("Subscriptions")
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                }
                                .padding()
                            }
                        }
                        .background(.lGray)
                        .cornerRadius(15)
                        .padding()
                        
                        //MARK: - Кнопки действий
                        if user.id != (authViewModel.currentUser?.id ?? "") {
                            HStack(spacing: 15) {
                                //MARK: - Кнопка "Сообщение"
                                if (UserHelper.isMessagesBlocked(viewModel: authViewModel, user: user) == nil) { // проверка что пользователя не блокнули
                                    NavigationLink(destination: NewChatView(userId: user.id)) {
                                        if isLoadingMessage { //лоадер если мы еще ищем id чата
                                            ProgressView()
                                        } else {
                                            HStack {
                                                Image(systemName: "message.fill")
                                                Text("Message")
                                            }
                                            .padding()
                                            .frame(width: 200, height: 35)
                                            .background(.gray)
                                            .foregroundColor(.white)
                                            .cornerRadius(15)
                                        }
                                    }
                                }
                                //MARK: - Кнопка "Подписаться"
                                Button(action: {
                                    if authViewModel.currentUser?.subscriptions.contains(user.id) == true {
                                        let index = authViewModel.currentUser?.subscriptions.firstIndex(where: { $0 == user.id })
                                        authViewModel.currentUser?.subscriptions.remove(at: index!)
                                        
                                        authViewModel.updateUsersFirebase(isAdd: false, str: "subscriptions", newStr: user.id, cUid: authViewModel.currentUser!.id)
                                        authViewModel.updateUsersFirebase(isAdd: false, str: "subscribers", newStr: authViewModel.currentUser!.id, cUid: user.id)
                                    } else {
                                        authViewModel.currentUser?.subscriptions.append(user.id)
                                        
                                        authViewModel.updateUsersFirebase(str: "subscriptions", newStr: user.id, cUid: authViewModel.currentUser!.id)
                                        authViewModel.updateUsersFirebase(str: "subscribers", newStr: authViewModel.currentUser!.id, cUid: user.id)
                                        
                                        //send notification
                                        Task {
                                            await authViewModel.sendNotification(
                                                header: "Skillify",
                                                playerId: user.id,
                                                messageText: "You have a new subscriber \(authViewModel.currentUser?.first_name ?? "")",
                                                targetText: authViewModel.currentUser?.id ?? "",
                                                type: .subscription,
                                                privacy: user.privacyData)
                                        }
                                    }
                                }) {
                                    if authViewModel.currentUser?.subscriptions.contains(user.id) == true {
                                        if authViewModel.currentUser?.subscribers.contains(user.id) == true {
                                            Image(systemName: "person.2.fill")
                                                .padding()
                                                .frame(width: 35, height: 35)
                                                .background(.blue)
                                                .foregroundColor(.green)
                                                .clipShape(Circle())
                                        } else {
                                            Image(systemName: "person.fill.checkmark")
                                                .padding()
                                                .frame(width: 35, height: 35)
                                                .background(.blue)
                                                .foregroundColor(.green)
                                                .clipShape(Circle())
                                        }
                                    } else {
                                        Image(systemName: "person.badge.plus")
                                            .padding()
                                            .frame(width: 35, height: 35)
                                            .background(.blue)
                                            .foregroundColor(.white)
                                            .clipShape(Circle())
                                    }
                                }
                                
                                //MARK: - CALLS
                                if UserHelper.isMessagesBlocked(viewModel: authViewModel, user: user) == nil
                                    && !(user.lastData?.contains(where: { $0 == "android" }) ?? false) // проверка что не андроид (тк на анроид еще нет звонков)
                                    && (user.blocked ?? 0 < 3) {
                                    // Кнопка "Позвонить"
                                    if callManager.callId == nil {
                                        Button(action: {
                                            if authViewModel.currentUser?.subscriptions.contains(user.id) == true &&
                                                authViewModel.currentUser?.subscribers.contains(user.id) == true
                                            {
                                                callManager.setCall(channelName: "\(authViewModel.currentUser!.id) \(user.id)", receiver: user, handler: authViewModel.currentUser!) {
                                                    callManager.startCall()
                                                    showPhoneCall = true
                                                }
                                            } else {
                                                isVisible = true
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                                    isVisible = false
                                                }
                                            }
                                        }) {
                                            Image(systemName: "phone.fill")
                                                .padding()
                                                .frame(width: 35, height: 35)
                                                .background(Color.green)
                                                .foregroundColor(.white)
                                                .clipShape(Circle())
                                        }
                                        .overlay(alignment: .topTrailing, content: { // звонки доступны только друзьям (нужно подписаться друг на друга)
                                            if isVisible {
                                                Text("Only for friends")
                                                    .padding(.vertical, 5)
                                                    .padding(.horizontal, 8)
                                                    .frame(width: 150, height: 40)
                                                    .background(.background)
                                                    .foregroundColor(.primary)
                                                    .cornerRadius(15)
                                                    .shadow(radius: 5)
                                                    .font(.caption)
                                                    .offset(y: -50)
                                            }
                                        })
                                        //MARK: - видео звонок
                                        Button(action: {
                                            if authViewModel.currentUser?.subscriptions.contains(user.id) == true &&
                                                authViewModel.currentUser?.subscribers.contains(user.id) == true
                                            {
                                                callManager.setCall(channelName: "\(authViewModel.currentUser!.id)-\(user.id)", receiver: user, handler: authViewModel.currentUser!, video: true) {
                                                    callManager.startCall()
                                                    showPhoneCall = true
                                                }
                                            } else {
                                                isVisible = true
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                                    isVisible = false
                                                }
                                            }
                                        }) {
                                            Image(systemName: "video")
                                                .padding()
                                                .frame(width: 35, height: 35)
                                                .background(Color.green)
                                                .foregroundColor(.white)
                                                .clipShape(Circle())
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        //MARK: - Список своих скиллов
                        VStack(alignment: .leading) {
                            Text("My Skills")
                                .font(.headline)
                                .padding(.top)
                            if user.selfSkills.count > 0 {
                                let viewModel = SkillsViewModel(authViewModel: authViewModel)
                                ForEach(user.selfSkills, id: \.self) { skill in
                                    VStack {
                                        excView(skill: skill, viewModel: viewModel, user: user)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 8)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(10)
                                    .onTapGesture {
                                        if user.id == (currentId) {
                                            let index = authViewModel.currentUser?.selfSkills.firstIndex(where: { $0.name == skill.name })
                                            authViewModel.currentUser?.selfSkills[index ?? 0].isSelected.toggle()
                                        }
                                    }
                                }
                            } else {
                                Text("For appologize user doesn't set any skills")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        
                        //MARK: - изучаемые скиллы
                        VStack(alignment: .leading) {
                            Text("I learning")
                                .font(.headline)
                                .padding(.top)
                            if user.learningSkills.count > 0 {
                                let viewModel = LearningSkillsViewModel(authViewModel: authViewModel)
                                ForEach(user.learningSkills, id: \.self) { skill in
                                    VStack {
                                        exc2View(skill: skill, viewModel: viewModel, user: user/*, isVisible: isVisible*/)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 8)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(10)
                                    .onTapGesture {
                                        if user.id == (currentId) {
                                            let index = authViewModel.currentUser?.learningSkills.firstIndex(where: { $0.name == skill.name })
                                            authViewModel.currentUser?.learningSkills[index ?? 0].isSelected.toggle()
                                        }
                                        //                                print(index)
                                    }
                                }
                            } else {
                                Text("For appologize user not set any skills")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    }
                    .onAppear {
                        self.subscribers = user.subscribers.count
                        self.subscriptions = user.subscriptions.count
                        self.currentId = authViewModel.currentUser?.id ?? ""
                        
                        if user.id == currentId { // только если это наш профиль - раскрываем первый свой скилл (дальше будет больше функционала в этом)
                            if (authViewModel.currentUser?.selfSkills.count)! > 0 && authViewModel.currentUser?.selfSkills[0] != nil {
                                authViewModel.currentUser?.selfSkills[0].isSelected = true
                            }
                        }
                        
                        //поиск id чата с текущим пользователем
                        isLoadingMessage = false
                    }
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Menu {
                                Button {
                                    selectedMenuItem = shareProfileMenuItem
                                } label: {
                                    Text("Share profile")
                                }
                                if user.id != (currentId) { // только если не наш профиль
                                    //                            Button("Report & block", action: {
                                    //                                selectedMenuItem = reportProfileMenuItem
                                    //                            })
                                    //MARK: - добавление в избранные пользователя
                                    if let favoritesUsers = authViewModel.currentUser?.favorites,
                                       favoritesUsers.contains(where: {$0.type == "user" && $0.id == user.id}) { // already in favorites
                                        Button{
                                            let fav = Favorite(id: user.id, type: "user")
                                            authViewModel.updateDataFirebase(isAdd: false, str: "favorites", newData: fav)
                                            let index = authViewModel.currentUser?.favorites.firstIndex(where: { $0.id == user.id })
                                            if let i = index {
                                                authViewModel.currentUser?.favorites.remove(at: i)
                                            }
                                        } label: {
                                            Text("Remove from favorite")
                                        }
                                    } else {
                                        Button{
                                            let fav = Favorite(id: user.id, type: "user")
                                            authViewModel.updateDataFirebase(isAdd: true, str: "favorites", newData: fav)
                                            authViewModel.currentUser?.favorites.append(fav)
                                        } label: {
                                            Text("Add to favorite")
                                        }
                                    }
                                    
                                    //MARK: - блокирование пользователя
                                    if let blockedUsers = authViewModel.currentUser?.blockedUsers, blockedUsers.contains(user.id) {
                                        // Если пользователь заблокирован
                                        if let index = blockedUsers.firstIndex(of: user.id) {
                                            Button("Unblock user", action: {
                                                authViewModel.currentUser?.blockedUsers.remove(at: index)
                                                syncDelFire(blockedUserID: user.id)
                                                // Здесь может потребоваться дополнительная логика для обновления состояния в authViewModel
                                            })
                                        }
                                    } else {
                                        // Если пользователь не заблокирован
                                        Button("Block user", action: {
                                            authViewModel.currentUser?.blockedUsers.append(user.id)
                                            syncAddFire(blockedUserID: user.id)
                                            // Здесь также может потребоваться дополнительная логика для обновления состояния
                                            dismiss()
                                        })
                                    }
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                            }
                        }
                    }
                    .sheet(item: $selectedMenuItem) { item in
                        switch item.id {
                        case "Share":
                            ShareProfileView(user: user)
                        case "Report":
                            SafariView(url:
                                        URL(string: "string")!)
                        default:
                            EmptyView()
                        }
                    }
                }
                .ignoresSafeArea(edges: .top)
                .navigationDestination(isPresented: $showPhoneCall) {
                    PhoneCallView().toolbar(.hidden, for: .tabBar)
                }
            }
        }
    }
    
    func isUserBlocked(user: User) -> Bool {
        if let blocked = user.blocked, blocked > 3 {
            return true
        } else if let _ = user.block {
            return true
        }
        
        return false
    }
    
    // MARK: - блокируем пользователя
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
    
    //MARK: - разблокируем пользователя
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
}

struct MenuItem: Identifiable {
    let id: String
}

// MARK: - аватарка
struct AvatarView: View {
    var avatarUrl: String
    var body: some View {
        VStack {
            if UserHelper.avatars.contains(avatarUrl.split(separator: ":").first.map(String.init) ?? "") { // если аватарка стандартная (из предустановленных)
                Image(avatarUrl.split(separator: ":").first.map(String.init) ?? "")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .foregroundColor(.gray)
                    .padding(.top, 10)
                    .frame(width: 100, height: 100)
                    .background(Color.fromRGBAString(avatarUrl.split(separator: ":").last.map(String.init) ?? "") ?? .blue.opacity(0.4))
                    .clipShape(Circle())
            } else if let url = URL(string: avatarUrl) { // если обычная картинка из firebase storage
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                } placeholder: {
                    Rectangle()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                }
                .frame(width: 100, height: 100)
                .clipShape(Circle())
            } else { // ну и если вообще ее нет
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .foregroundColor(.gray)
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 130)
        .padding(.top)
        .ignoresSafeArea(edges: .top)
    }
}

//MARK: - отображение изучаемого скилла
struct exc2View: View {
    var skill: Skill
    var viewModel: LearningSkillsViewModel
    var user: User
    @EnvironmentObject var authViewModel: AuthViewModel
    @State var isVisible: Bool = false
    
    var body: some View {
        HStack {
            if let skillIndex = viewModel.skills.firstIndex(where: { $0.name == skill.name }) {
                // Получить iconName и отобразить изображение
                let iconName = viewModel.skills[skillIndex].iconName
                Image(systemName: iconName!)
                    .symbolRenderingMode(.multicolor)
                    .frame(width: 25, height: 25)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .clipShape(Circle())
            } else {
                Image(systemName: "star")
                    .symbolRenderingMode(.multicolor)
                    .frame(width: 25, height: 25)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .clipShape(Circle())
            }
            Text(skill.name)
            Spacer()
            VStack(spacing: 4) {
                let c2: Color = skill.level == "Advanced" ? .blue : .white
                Image(systemName: "rectangle.fill")
                    .resizable()
                    .frame(width: 20, height: 4)
                    .foregroundColor(c2)
                
                let c1: Color = skill.level == "Intermediate" || skill.level == "Advanced" ? .blue : .white
                Image(systemName: "rectangle.fill")
                    .resizable()
                    .frame(width: 20, height: 4)
                    .foregroundColor(c1)
                
                Image(systemName: "rectangle.fill")
                    .resizable()
                    .frame(width: 20, height: 4)
                    .foregroundColor(.blue)
            }
            .padding(.horizontal)
        }
        if user.id == authViewModel.currentUser?.id && skill.isSelected {
            VStack {
                HStack {
                    Text("Beginner")
                        .padding(.leading)
                        .foregroundColor(.gray)
                    Spacer()
                    Text("Advanced")
                        .padding(.trailing)
                        .foregroundColor(.gray)
                }
                SkillProgressView(skillLevel: skill.level!)
                                    .padding(.horizontal)
                Text("Intermediate")
                    .foregroundColor(.gray)
//                HStack {
//                    Button {
//                        
//                    } label: {
//                        Text("Edit")
//                            .font(.caption)
//                            .padding(.vertical, 5)
//                            .padding(.horizontal, 8)
//                            .background(.gray)
//                            .foregroundColor(.white)
//                            .cornerRadius(15)
//                    }
//                    Spacer()
//                    Button {
//                        isVisible.toggle()
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                            isVisible = false
//                        }
//                    } label: {
//                        HStack {
//                            Text("Check your skill")
//                                .font(.caption)
//                        }
//                        .padding(.vertical, 5)
//                        .padding(.horizontal, 8)
//                        .background(.blue)
//                        .foregroundColor(.white)
//                        .cornerRadius(15)
//                    }
//                    .overlay(alignment: .top, content: {
//                        if isVisible {
//                            Text("Availaible soon")
//                                .padding(.vertical, 5)
//                                .padding(.horizontal, 8)
//                                .frame(width: 100, height: 40)
//                                .background(.background)
//                                .foregroundColor(.primary)
//                                .cornerRadius(15)
//                                .shadow(radius: 5)
//                                .font(.caption)
//                                .offset(y: -50)
//                        }
//                    })
//                }
//                .padding(.horizontal)
//                .padding(.bottom, 10)
            }
        }
    }
}

//MARK: - свой скилл
struct excView: View {
    var skill: Skill
    var viewModel: SkillsViewModel
    var user: User
    @EnvironmentObject var authViewModel: AuthViewModel
    @State var isVisible: Bool = false
    
    var body: some View {
        HStack {
            if let skillIndex = viewModel.skills.firstIndex(where: { $0.name == skill.name }) {
                // Получить iconName и отобразить изображение
                let iconName = viewModel.skills[skillIndex].iconName
                Image(systemName: iconName!)
                    .symbolRenderingMode(.multicolor)
                    .frame(width: 25, height: 25)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .clipShape(Circle())
            } else {
                Image(systemName: "star")
                    .symbolRenderingMode(.multicolor)
                    .frame(width: 25, height: 25)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .clipShape(Circle())
            }
            Text(skill.name)
            Spacer()
            VStack(spacing: 4) {
                Image(systemName: "rectangle.fill")
                    .resizable()
                    .frame(width: 20, height: 4)
                    .foregroundColor(skill.level == "Advanced" ? .blue : .white)
                
                Image(systemName: "rectangle.fill")
                    .resizable()
                    .frame(width: 20, height: 4)
                    .foregroundColor(skill.level == "Intermediate" || skill.level == "Advanced" ? .blue : .white)
                
                Image(systemName: "rectangle.fill")
                    .resizable()
                    .frame(width: 20, height: 4)
                    .foregroundColor(.blue)
            }
            .padding(.horizontal)
        }
        if user.id == authViewModel.currentUser?.id && skill.isSelected {
            VStack {
                HStack {
                    Text("Beginner")
                        .padding(.leading)
                        .foregroundColor(.gray)
                    Spacer()
                    Text("Advanced")
                        .padding(.trailing)
                        .foregroundColor(.gray)
                }
                SkillProgressView(skillLevel: skill.level!)
                                    .padding(.horizontal)
                Text("Intermediate")
                    .foregroundColor(.gray)
//                HStack {
//                    Button {
//                        
//                    } label: {
//                        Text("Edit")
//                            .font(.caption)
//                            .padding(.vertical, 5)
//                            .padding(.horizontal, 8)
//                            .background(.gray)
//                            .foregroundColor(.white)
//                            .cornerRadius(15)
//                    }
//                    Spacer()
//                    Button {
//                        isVisible = true
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                            isVisible = false
//                        }
//                    } label: {
//                        HStack {
//                            Text("Check your skill")
//                                .font(.caption)
//                        }
//                        .padding(.vertical, 5)
//                        .padding(.horizontal, 8)
//                        .background(.blue)
//                        .foregroundColor(.white)
//                        .cornerRadius(15)
//                    }
//                    .overlay(alignment: .top, content: {
//                        if isVisible {
//                            Text("Availaible soon")
//                                .font(.caption)
//                                .padding(.vertical, 5)
//                                .padding(.horizontal, 8)
//                                .frame(width: 100, height: 40)
//                                .foregroundColor(.primary)
//                                .background(.background)
//                                .cornerRadius(15)
//                                .shadow(radius: 5)
//                                .offset(y: -50)
//                        }
//                    })
//                }
//                .padding(.horizontal)
//                .padding(.bottom, 10)
            }
        }
    }
}

struct SkillProgressView: View {
    var skillLevel: String
    
    private var progressValue: Double {
        switch skillLevel {
        case "Beginner": return 0.2
        case "Intermediate": return 0.5
        case "Advanced": return 1.0
        default: return 0
        }
    }
    
    var body: some View {
        ProgressView(value: progressValue)
    }
}

#Preview {
    ProfileView(user: User(id: "gs1mFrOnlaYcb4h0OdgteWeY6Yf2", first_name: "ELian", last_name: "Test", bio: "vk jj .", email: "", block: nil, nickname: "nick", phone: "+8", birthday: Date()))
        .environmentObject(AuthViewModel.mock)
        .environmentObject(CallManager.mock)
        .environmentObject(MessagesViewModel.mock)
}
