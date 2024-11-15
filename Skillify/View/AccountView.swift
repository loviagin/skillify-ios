//
//  AccountView.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 19.12.2023.
//


import SwiftUI
import FirebaseFirestore
import Kingfisher

struct AccountView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var showSafari = false
    @Binding var blocked: Int   
    @State var isOnline: Bool = true
    
    private var avatarURL: String? {
        authViewModel.currentUser?.urlAvatar
    }
    
    private var avatarBase: String {
        avatarURL?.split(separator: ":").first.map(String.init) ?? ""
    }
    
    private var avatarColor: Color {
        Color.fromRGBAString(avatarURL?.split(separator: ":").last.map(String.init) ?? "") ?? .blue.opacity(0.4)
    }
    
    private var displayName: String {
        "\(authViewModel.currentUser?.first_name ?? "First") \(authViewModel.currentUser?.last_name ?? "Last Name")"
    }
    
    private var nickname: String {
        "@\(authViewModel.currentUser?.nickname ?? "nickname")"
    }
            
    var body: some View {
        NavigationView {
            ZStack {
                List {
                    Section {
                        NavigationLink(destination: EditProfileView().toolbar(.hidden, for: .tabBar)) {
                            profileHeader
                        }
                        if let currentUser = authViewModel.currentUser {
                            LinkSettingView(nameIcon: "eye",
                                            name: "View profile",
                                            action: AnyView(ProfileView(user: currentUser)))
                        }
                        Toggle(isOn: $isOnline) {
                            Text("Status online \(UserHelper.isUserPro(authViewModel.currentUser?.pro) ? "" : "(only for pro)")")
                        }
                        .disabled(!UserHelper.isUserPro(authViewModel.currentUser?.pro))
                        .onChange(of: isOnline) { _, _ in
                            Task {
                                if isOnline {
                                    await authViewModel.onlineMode()
                                } else {
                                    await authViewModel.offlineMode()
                                }
                            }
                        }
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
                    
                    Section(header: Text("Settings")) {
                        LinkSettingView(nameIcon: "hand.raised.circle", name: "Privacy & Security", action: AnyView(PrivacyView()))
                        LinkSettingView(nameIcon: "iphone.smartbatterycase.gen2", name: "My devices", action: AnyView(DevicesView()))
                    }
                    
                    Section(header: Text("About us")) {
                        PointSettingView(nameIcon: "link",
                                         name: "Follow us on Instagram",
                                         action: {
                            openInstagramProfile(username: "_skillify")
                        })
                        PointSettingView(nameIcon: "globe", name: "Check our website", action: {
                            showSafari = true
                        })
                        .sheet(isPresented: $showSafari) {
                            SafariView(url:
                                        URL(string: "https://skillify.space/")!)
                        }
                    }
                    Section {
                        LinkSettingView(nameIcon: "gearshape", name: "Other settings", action: AnyView(SettingsView()))
                        PointSettingView(nameIcon: "rectangle.portrait.and.arrow.right",
                                         name: "Log out",
                                         action: {
                            authViewModel.signOut()
                        })
                        .foregroundColor(.red)
                    }
                }
            } // zStack
        }
    }
    
    var profileHeader: some View {
            HStack {
                if UserHelper.avatars.contains(avatarBase) {
                    Image(avatarBase)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .padding(.top, 10)
                        .frame(width: 80, height: 80)
                        .background(avatarColor)
                        .clipShape(Circle())
                        .padding(.vertical, 10)
                } else if let urlString = avatarURL, let url = URL(string: urlString) {
                    KFImage(url)
                            .resizable()
                            .placeholder {
                                Image("user")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                            }
                            .clipShape(Circle())
                            .frame(width: 80, height: 80)
                            .padding(.vertical, 10)
                } else {
                    Image("user")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .padding(.vertical, 10)
                }
                VStack(alignment: .leading) {
                    Text(displayName)
                        .font(.title2)
                    Text(nickname)
                        .font(.title3)
                        .foregroundColor(.gray)
                }.padding()
                Spacer()
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

#Preview {
    AccountView(blocked: .constant(0))
        .environmentObject(AuthViewModel.mock)
        .environmentObject(ChatViewModel.mock)
        .environmentObject(CallManager.mock)
}
