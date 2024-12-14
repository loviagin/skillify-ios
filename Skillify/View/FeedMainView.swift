//
//  FeedMainView.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 19.12.2023.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import StoreKit
import Kingfisher
import TipKit
import GoogleMobileAds

struct FeedMainView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ChipsViewModel()
    @StateObject private var userViewModel = UserViewModel()
    @StateObject private var pointsViewModel = PointsViewModel()
    @AppStorage("pointIntroduced") var pointIntroduced = false
    
    @State private var showSelfSkill = false
    @State private var showLearningSkill = false
    @State private var showNewDailyPoints = false
    
    @State private var selectedValue: SearchType = .learningsSkills
    @State var searchViewModel = SearchViewModel(chipArray: [])
    @State var newCourses: [Course] = [Course(preview: "https://avatars.yandex.net/get-music-content/6201394/2e88bc3c.a.23429889-1/m1000x1000?webp=false", title: "Guitar Pro", description: "Get up your guitar and start playing!", rating: 4.8), Course(preview: "https://avatars.mds.yandex.net/i?id=b60e7cfd0b5e5dc7e1a5c8eda6e5e176_l-9138034-images-thumbs&n=13", title: "Piano Pro", description: "Get up your piano and start playing!", rating: 4.9)]
    
    @State var proViewShow = false
    @State var profileViewShow = false
    
    @State private var systemMessage: String? = nil
    
    var body: some View {
        NavigationStack {
            VStack {
                HeaderMainView()
                    .environmentObject(pointsViewModel)
                    .padding(.vertical, 5)
                
                if let message = systemMessage {
                    HStack {
                        Text(message)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color("warningColor").opacity(0.5))
                            .cornerRadius(15)
                            .padding(.horizontal)
                    }
                    .onTapGesture {
                        systemMessage = nil
                    }
                }
                
                if authViewModel.userState == .loading && authViewModel.currentUser == nil {
                    ProgressView()
                        .frame(width: 50, height: 50)
                }
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Top Users")
                                .font(.headline)
                                .bold()
                            
                            Spacer()
                        }
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack {
                                SelfStoryImageView()
                                    .onTapGesture {
                                        if let user = authViewModel.currentUser {
                                            if !UserHelper.isUserPro(user.proDate) {
                                                proViewShow = true
                                            } else {
                                                profileViewShow = true
                                            }
                                        }
                                    }
                                
                                if !authViewModel.users.isEmpty {
                                    ForEach(authViewModel.users) { user in
                                        NavigationLink(destination: ProfileView(user: user)) {
                                            StoryImageView(u: user).foregroundColor(.brandBlue)
                                        }
                                    }
                                }
                            }
                        }
                        .sheet(isPresented: $proViewShow){
                            ProView()
                        }
                        .sheet(isPresented: $profileViewShow) {
                            NavigationStack {
                                ProfileView(user: authViewModel.currentUser!)
                                    .toolbar(.hidden, for: .navigationBar)
                            }
                        }
                        
                        //                        TipView(TipNewVersion156())
                        //                            .padding(.trailing, 10)
                        
                        VStack {
                            HStack {
                                Text("New courses")
                                    .font(.headline)
                                    .bold()
                                
                                Spacer()
                            }
                            
                            ForEach(newCourses) { course in
                                HorizontalCourseView(course: course)
                                Divider()
                            }
                        }
                        .padding([.bottom, .top, .trailing])
                        
                        NavigationLink(
                            destination: UsersSearchView()
                        ) {
                            Text("Search users, skills...")
                                .padding()
                                .frame(maxWidth: .infinity, maxHeight: 35, alignment: .leading)
                                .background(.lGray)
                                .foregroundColor(.gray)
                                .cornerRadius(10)
                                .padding(.bottom)
                        }
                        
                        Picker("Выберите элемент", selection: $selectedValue) {
                            ForEach(SearchType.allCases, id: \.self) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .background(.blue.opacity(0.2))
                        .cornerRadius(8)
                        
                        // Conditional content based on selectedValue
                        ChipContainerView(viewModel: viewModel, searchViewModel: searchViewModel)
                        
                        if let auth = authViewModel.currentUser {
                            UserSearchView(viewModel: searchViewModel, id: auth.id)
                        }
                        
                        if let user = authViewModel.currentUser, !UserHelper.isUserPro(user.proDate) {
                            GeometryReader { geometry in
                                let adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(geometry.size.width)
                                
                                VStack {
                                    Spacer()
                                    BannerView(adSize)
                                        .frame(height: adSize.size.height)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 55)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 5)
                } // scrollView
                .refreshable {
                    Task {
                        await authViewModel.loadUser()
                        authViewModel.fetchAllUsers()
                        updateSearch()
                        pointsViewModel.reload()
                    }
                }
            }
            .onAppear {
                self.searchViewModel.authViewModel = authViewModel
                self.searchViewModel.chipArray = viewModel.chipArray
                updateSearch()
                Firestore.firestore().collection("admin").document("system").getDocument { (document, error) in
                    if let document = document, document.exists {
                        systemMessage = document.get("showHomeAlert") as? String
                    } else {
                        print("error while loading admin doc: \(error?.localizedDescription ?? "No error description")")
                    }
                }
//                updateUserFields()
//                firebaseAction()
            }
            .onChange(of: pointsViewModel.newDailyPoints) { _, newValue in
                if newValue == true {
                    self.showNewDailyPoints = true
                    pointsViewModel.newDailyPoints = false
                }
            }
            .onChange(of: selectedValue) { _, _ in
                updateSearch()
            }
            .onOpenURL(perform: handleURL)
            .navigationDestination(item: $userViewModel.profileUser) { user in
                ProfileView(user: user)
            }
            .navigationDestination(isPresented: $showSelfSkill) {
                SelfSkillsView(isRegistration: true)
            }
            .navigationDestination(isPresented: $showLearningSkill) {
                LearningSkillsView(isRegistration: true)
            }
            .fullScreenCover(isPresented: $pointIntroduced) {
                MainOnboardingView()
            }
            .alert("🎉 +10\n\nNew Daily Talents!", isPresented: $showNewDailyPoints, actions: {
                Button("Sounds great!") {
                    showNewDailyPoints = false
                }
            }, message: {
                Text("Open the app every day to earn more Talents")
            })
            .task {
                if authViewModel.currentUser?.selfSkills.isEmpty ?? false {
                    showSelfSkill = true
                } else if authViewModel.currentUser?.learningSkills.isEmpty ?? false {
                    showLearningSkill = true
                } 
            }
        }
    }
    
    //MARK: - firebase add/remove field(-s)
//    func firebaseAction() {
//        let db = Firestore.firestore()
//        let usersCollection = db.collection("users")
//        
//        // Получаем все документы из коллекции `users`
//        usersCollection.getDocuments { snapshot, error in
//            if let error = error {
//                print("Ошибка при получении документов: \(error.localizedDescription)")
//                return
//            }
//            
//            guard let documents = snapshot?.documents else {
//                print("Нет документов в коллекции `users`.")
//                return
//            }
//            
//            for document in documents {
//                document.reference.updateData([
//                    "points": FieldValue.delete()
//                ]) { error in
//                    if let error = error {
//                        print("Ошибка при удалении поля `blocked` из документа \(document.documentID): \(error.localizedDescription)")
//                    } else {
//                        print("Поле `blocked` успешно удалено из документа \(document.documentID).")
//                    }
//                }
//            }
//        }
//    }
    
    private func handleURL(_ url: URL) {
        // Проверка, что пользователь залогинен
        guard Auth.auth().currentUser != nil else { return }
        
        if url.scheme == "skillify" {
            let pathComponents = url.pathComponents
            
            if pathComponents.contains("m") {
                // Открытие конкретного чата
                if let chatId = pathComponents.last {
                    authViewModel.selectedTab = .chats
                    userViewModel.loadUser(byId: chatId) // Загружает данные для профиля
                }
            } else if url.absoluteString.contains("@") {
                // Открытие профиля пользователя по нику
                let nickname = url.absoluteString.components(separatedBy: "@").last ?? ""
                authViewModel.selectedTab = .home
                userViewModel.loadUser(byNickname: nickname)
            }
        }
    }
    
    func updateSearch() {
        if authViewModel.userState == UserState.loggedIn {
            DispatchQueue.main.async {
                if selectedValue == .learningsSkills {
                    if let skills = authViewModel.currentUser?.learningSkills {
                        if !skills.isEmpty {
                            viewModel.updateChips(with: skills)
                        } else {
                            viewModel.resetChipArray()
                        }
                        searchViewModel.switchSearchType(learning: true, skills: viewModel.chipArray)
                    }
                } else {
                    if let skills = authViewModel.currentUser?.selfSkills {
                        if !skills.isEmpty {
                            viewModel.updateChips(with: skills)
                        } else {
                            viewModel.resetChipArray()
                        }
                        searchViewModel.switchSearchType(learning: false, skills: viewModel.chipArray)
                    }
                }
            }
        }
    }
}

struct HeaderMainView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var callManager: CallManager
    @EnvironmentObject var viewModel: PointsViewModel
    
    @State private var showTopView = false
    
    var body: some View {
        VStack(spacing: 5) {
            if showTopView {
                CallTopView()
            }
            
//            HStack {
//                if let user = authViewModel.currentUser, UserHelper.isUserPro(user.proDate) {
//                    Image("logoPro")
//                        .resizable()
//                        .scaledToFit()
//                        .frame(width: 125)
//                } else {
//                    Image("logo")
//                        .resizable()
//                        .scaledToFit()
//                        .frame(width: 125)
//                }
//            }
//            .padding(.bottom, 5)
//            .padding(.horizontal, 15)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Hi, \(authViewModel.currentUser?.first_name ?? "")")
                        .font(.title)
                        .bold()
                    
                    Text("What do you want to learn today?")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }
                
                Spacer()
                
                PointScoreView()
                    .environmentObject(viewModel)
            }
            
            Divider()
        }
        .padding(.horizontal)
        .onChange(of: callManager.show) { _, _ in
            withAnimation {
                showTopView = callManager.show
            }
        }
    }
}

struct SelfStoryImageView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    var body: some View {
        VStack(alignment: .center) {
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if UserHelper.avatars.contains(authViewModel.currentUser?.urlAvatar.split(separator: ":").first.map(String.init) ?? "") {
                        Image(authViewModel.currentUser!.urlAvatar.split(separator: ":").first.map(String.init) ?? "")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .padding(.top, 10)
                            .frame(width: 70, height: 70)
                            .background(Color.fromRGBAString(authViewModel.currentUser?.urlAvatar.split(separator: ":").last.map(String.init) ?? "") ?? .blue.opacity(0.4))
                            .clipShape(Circle())
                    } else if let urlString = authViewModel.currentUser?.urlAvatar, !urlString.isEmpty, let url = URL(string: urlString) {
                        KFImage(url)
                            .resizable()
                            .placeholder {
                                Image("avatar1")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 70, height: 70)
                                    .clipShape(Circle())
                                    .clipped()
                            }
                            .cacheMemoryOnly()
                            .loadDiskFileSynchronously()
                            .scaledToFill()
                            .frame(width: 70, height: 70)
                            .clipShape(Circle())
                            .clipped()
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 70, height: 70)
                            .clipShape(Circle())
                    }
                }
                .overlay(Circle().stroke(LinearGradient(colors: [.blue, .red], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2))
                .padding(3)
                
                if !UserHelper.isUserPro(authViewModel.currentUser?.proDate) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(
                            LinearGradient(colors: [.blue, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .overlay(Circle().stroke(Color.main, lineWidth: 2))
                    //                        .offset(x: -2, y: -2)
                    
                } else if let online = authViewModel.currentUser?.online, online == true {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .offset(x: -4, y: -4)
                }
            }
            if let u = authViewModel.currentUser {
                HStack(spacing: 3) {
                    Text("\(u.first_name.count > 8 ? u.first_name.prefix(8) + "..." : u.first_name)")
                        .font(.callout)
                        .fontWeight(.bold)
                    
                    if let data = u.tags, data.contains("verified") {
                        Image("verify")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 15, height: 15)
                    } else if let data = u.tags, data.contains("admin") {
                        Image("gold")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 15, height: 15)
                    } else if UserHelper.isUserPro(u.proDate), let data = u.proData, let status = data.first(where: { $0.hasPrefix("status:") }) {
                        Image(systemName: String(status.split(separator: ":").last ?? Substring(status)))
                            .resizable()
                            .scaledToFill()
                            .frame(width: 15, height: 15)
                            .foregroundColor(.brandBlue)
                    }
                }
            }
        }
    }
}

struct StoryImageView: View {
    let u: User
    
    var body: some View {
        VStack(alignment: .center) {
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if UserHelper.avatars.contains(u.urlAvatar.split(separator: ":").first.map(String.init) ?? "") {
                        Image(u.urlAvatar.split(separator: ":").first.map(String.init) ?? "")
                            .resizable()
                            .foregroundColor(.gray)
                            .aspectRatio(contentMode: .fill)
                            .padding(.top, 10)
                            .frame(width: 70, height: 70)
                            .background(Color.fromRGBAString(u.urlAvatar.split(separator: ":").last.map(String.init) ?? "") ?? .blue.opacity(0.4))
                            .clipShape(Circle())
                    } else if let url = URL(string: u.urlAvatar) {
                        KFImage(url)
                            .resizable()
                            .placeholder {
                                Image("avatar1")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 70, height: 70)
                                    .clipShape(Circle())
                                    .clipped()
                            }
                            .cacheMemoryOnly()
                            .loadDiskFileSynchronously()
                            .scaledToFill()
                            .frame(width: 70, height: 70)
                            .clipShape(Circle())
                            .clipped()
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .foregroundColor(.gray)
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 70, height: 70)
                            .clipShape(Circle())
                    }
                }
                .overlay(Circle().stroke(LinearGradient(colors: [.blue, .red], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2))
                .padding(3)
                
                if u.online ?? false {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .offset(x: -4, y: -4)
                }
            }
            
            HStack(spacing: 3) {
                Text("\(u.first_name.count > 8 ? u.first_name.prefix(8) + "..." : u.first_name)")
                    .font(.callout)
                
                if let data = u.tags, data.contains("verified") {
                    Image("verify")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 15, height: 15)
                } else if let data = u.tags, data.contains("admin") {
                    Image("gold")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 15, height: 15)
                } else if UserHelper.isUserPro(u.proDate), let data = u.proData, let status = data.first(where: { $0.hasPrefix("status:") }) {
                    Image(systemName: String(status.split(separator: ":").last ?? Substring(status)))
                        .resizable()
                        .scaledToFill()
                        .frame(width: 15, height: 15)
                }
            }
        }
        .padding(.trailing, 5)
    }
}

struct UserSearchView: View {
    @ObservedObject var viewModel: SearchViewModel
    let id: String
    @State var showProfile = false
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                ForEach(viewModel.users) { user in
                    NavigationLink(destination: ProfileView(user: user)) {
                        SearchElementView(user: user)
                            .foregroundColor(Color.primary)
                    }
                }
            }
        }
    }
}

#Preview {
    FeedMainView()
        .environmentObject(AuthViewModel.mock)
        .environmentObject(ChatViewModel.mock)
        .environmentObject(CallManager.mock)
}

//struct TipNewVersion156: Tip {
//    var title: Text {
//        Text("New version 1.5.6")
//    }
//    
//    var message: Text? {
//        Text("🚀 Audio messages have been added to chats.\n🚀 Now you can close photos and videos with a swipe down in chats.")
//    }
//    
//    var image: Image? {
//        Image(systemName: "wand.and.stars")
//            .symbolRenderingMode(.palette)
//    }
//}
