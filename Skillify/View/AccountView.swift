//
//  AccountView.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 19.12.2023.
//


import SwiftUI
import FirebaseFirestore

struct AccountView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
        
    var body: some View {
        if authViewModel.isLoading {
            ProgressView()
        } else if authViewModel.currentUser?.nickname == "" {
            EditProfileView()
        } else if authViewModel.currentUser?.blocked ?? 0 > 3 || authViewModel.currentUser?.block != nil {
            BlockedView(text: authViewModel.currentUser?.block)
        } else {
            TabsMainView()
        }
    }
}

struct TabsMainView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var selectedTab = 0
    @State var blocked: Int = 0
    
    @State var showSelfSkill = false
    @State var showLearningSkill = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            FeedMainView(extraSkillsList: [])
                .tabItem {
                    Label("Main", systemImage: "house.circle")
                        .environment(\.symbolVariants, selectedTab == 0 ? .fill : .none)
                }
                .tag(0)
            
            DiscoverView()
                .tabItem {
                    Label("Discover", systemImage: "magnifyingglass.circle")
                        .environment(\.symbolVariants, selectedTab == 1 ? .fill : .none)
                }
                .tag(1)
            
            MainAccountView(blocked: $blocked)
                .tabItem {
                    Label("Account", systemImage: "person.crop.circle")
                        .environment(\.symbolVariants, selectedTab == 3 ? .fill : .none)
                }
                .toolbar(.visible, for: .tabBar)
                .tag(3)
        }
        .tabViewStyle(DefaultTabViewStyle())
        .background(Color.gray)
        .navigationDestination(isPresented: $showSelfSkill) {
            SelfSkillsView(authViewModel: authViewModel, isRegistration: true)
        }
        .navigationDestination(isPresented: $showLearningSkill) {
            LearningSkillsView(authViewModel: authViewModel, isRegistration: true)
        }
        .onAppear {
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithDefaultBackground()
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                if authViewModel.currentUser?.selfSkills.isEmpty ?? false {
                    showSelfSkill = true
                } else if authViewModel.currentUser?.learningSkills.isEmpty ?? false {
                    showLearningSkill = true
                }
            }
        }
    }
}

struct PointSettingView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var nameIcon: String
    var name: String
    var action: () -> Void
    
    var body: some View {
        Button (action: action) {
            HStack {
                Image(systemName: nameIcon)
                    .padding(.trailing, 5)
                    .padding(.vertical, 10)
                Text(name)
                Spacer()
                Image(systemName: "chevron.right")
                    .padding(.trailing, 5)
            }
        }
    }
}

struct LinkSettingView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var nameIcon: String
    var name: String
    var action: AnyView
    
    var body: some View {
        NavigationLink(destination: action) {
            HStack {
                Image(systemName: nameIcon)
                    .padding(.trailing, 5)
                    .padding(.vertical, 10)
                Text(name)
                Spacer()
            }
        }
    }
}

struct MainAccountView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var showSafari = false
    @Binding var blocked: Int   
    @State var isOnline: Bool = true
    
    @State var showProfile = false
        
    var body: some View {
        NavigationView {
            ZStack {
                List {
                    Section {
                        NavigationLink(destination: EditProfileView().toolbar(.hidden, for: .tabBar)) {
                            HStack {
                                if UserHelper.avatars.contains(authViewModel.currentUser?.urlAvatar.split(separator: ":").first.map(String.init) ?? "") {
                                    Image(authViewModel.currentUser!.urlAvatar.split(separator: ":").first.map(String.init) ?? "")
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .padding(.top, 10)
                                        .frame(width: 80, height: 80)
                                        .background(Color.fromRGBAString(authViewModel.currentUser?.urlAvatar.split(separator: ":").last.map(String.init) ?? "") ?? .blue.opacity(0.4))
                                        .padding(.vertical, 10)
                                        .clipShape(Circle())
                                } else if let urlString = authViewModel.currentUser?.urlAvatar, let url = URL(string: urlString) {
                                    AsyncImage(url: url) { image in
                                        image
                                            .resizable()
                                            .clipShape(Circle())
                                    } placeholder: {
                                        Image("user") // Ваш плейсхолдер
                                            .resizable()
                                    }
                                    .frame(width: 80, height: 80)
                                    .padding(.vertical, 10)
                                } else {
                                    Image("user") // Тот же плейсхолдер, если URL не существует
                                        .resizable()
                                        .frame(width: 80, height: 80)
                                        .padding(.vertical, 10)
                                }
                                VStack(alignment: .leading) {
                                    Text("\(authViewModel.currentUser?.first_name ?? "First") \(authViewModel.currentUser?.last_name ?? "Last Name")")
                                        .font(.title2)
                                    Text("@\(authViewModel.currentUser?.nickname ?? "nickname")")
                                        .font(.title3)
                                        .foregroundColor(.gray)
                                }.padding()
                                Spacer()
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if let currentUser = authViewModel.currentUser {
                            LinkSettingView(nameIcon: "eye",
                                            name: "View profile",
                                            action: AnyView(ProfileView(showProfile: $showProfile, user: currentUser)))
                        }
                        Toggle(isOn: $isOnline) {
                            Text("Status online \(UserHelper.isUserPro(authViewModel.currentUser?.pro) ? "" : "(only for pro)")")
                        }
                        .disabled(!UserHelper.isUserPro(authViewModel.currentUser?.pro))
                        .onChange(of: isOnline) { _ in
                            if isOnline {
                                authViewModel.onlineMode()
                            } else {
                                authViewModel.offlineMode()
                            }
                        }
                        
                        //                    LinkSettingView(nameIcon: "paperplane.fill",
                        //                                    name: "Share your profile",
                        //                                    action: AnyView(ShareProfileView()))
                        //                }
                    }
                    Section(header: Text("Configure your account")) {
                        NavigationLink(destination: ProView()) {
                            HStack {
                                Image(systemName: "bolt.fill")
                                    .foregroundColor(.brandBlue)
                                    .padding(.trailing, 10)
                                    .padding(.vertical, 10)
                                Text("Skillify Pro")
                                    .foregroundStyle(.brandBlue)
                                Spacer()
                            }
                        }
                        LinkSettingView(nameIcon: "books.vertical", name: "My Skills", action: AnyView(SelfSkillsView(authViewModel: authViewModel)))
                        LinkSettingView(nameIcon: "book", name: "Learning Skills", action: AnyView(LearningSkillsView(authViewModel: authViewModel)))
                    }
                    
                    //                    if let user = authViewModel.currentUser, UserHelper.isUserPro(user.pro) {
                    Section(header: Text("Settings")) {
                        LinkSettingView(nameIcon: "hand.raised.circle", name: "Privacy & Security", action: AnyView(PrivacyView()))
                        LinkSettingView(nameIcon: "iphone.smartbatterycase.gen2", name: "My devices", action: AnyView(DevicesView()))
                    }
                    //                    }
                    
                    Section(header: Text("About us")) {
                        //                VStack {
                        PointSettingView(nameIcon: "link",
                                         name: "Follow us on Instagram",
                                         action: {
                            openInstagramProfile(username: "_skillify")
                        })
                        //                    Divider()
                        PointSettingView(nameIcon: "globe", name: "Check our website", action: {
                            showSafari = true
                        })
                        .sheet(isPresented: $showSafari) {
                            SafariView(url:
                                        URL(string: "https://skillify.space/")!)
                        }
//                        Link(destination: URL(string: "skillify:profile/id123555545")!) {
//                                    Text("Открыть профиль")
//                                        .padding()
//                                        .foregroundColor(.white)
//                                        .background(Color.blue)
//                                        .cornerRadius(5)
//                                }
                    }
                    Section {
                        LinkSettingView(nameIcon: "gearshape", name: "Other settings", action: AnyView(SettingsView()))
                        //                    Divider()
                        PointSettingView(nameIcon: "rectangle.portrait.and.arrow.right",
                                         name: "Log out",
                                         action: {
                            //                        print("clicked out")
                            authViewModel.signOut()
                        })
                        .foregroundColor(.red)
                    }
                }
//                if showA1 {
//                    // Ваше вью подсказки, которое может быть простым как TutorialOverlayView
//                    AOverlayView()
//                        .transition(.opacity)
//                        .onTapGesture {
//                            withAnimation {
//                                UserDefaults.standard.set(true, forKey: "a1")
//                                showA1 = false
//                            }
//                        }
//                }
            } // zStack
//            .onAppear {
//                UserDefaults.standard.set(true, forKey: "hi1")
//            }
        }
    }
    
    func openInstagramProfile(username: String) {
        let appURL = URL(string: "instagram://user?username=\(username)")!
        let webURL = URL(string: "https://www.instagram.com/\(username)/")!
        
        if UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.open(webURL, options: [:], completionHandler: nil)
        }
    }
}

//struct AOverlayView: View {
//    var body: some View {
//        Image("a1")
//            .resizable()
//            .scaledToFill()
//            .opacity(0.9)
//            .ignoresSafeArea()
//            Text("You can set self and learning skills in these two sections for the best experience in people search")
//                .foregroundColor(.white)
//                .padding()
//                .background(Color.black.opacity(0.7))
//                .cornerRadius(10)
//                .padding(.bottom, 140)
//    }
//}

