//
//  FeedMainView.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 19.12.2023.
//

import SwiftUI
import FirebaseFirestore
import StoreKit
import Kingfisher
import TipKit

struct FeedMainView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject var viewModel = ChipsViewModel()

    @State var showProfileView: Bool = false
    @State private var selectedValue: SearchType = .learningsSkills
    @State private var isEditSettings = false
    @State var searchViewModel = SearchViewModel(chipArray: [])
    
    @State var extraSkillsList: [String]
    @State private var selectedSkill: String = "Graphic Design"
    @State var isFavorite: Bool = false
    @State var proViewShow = false
    @State var profileViewShow = false
    
    @State var profileUser: User?
    @State private var systemMessage: String? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    HeaderMainView()
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
                    
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Top Users")
                                    .font(.headline)
                                    .bold()
                                
                                Spacer()
                                
                                Button("View all") {
                                    
                                }
                            }
                            
                            ScrollView(.horizontal, showsIndicators: false){
                                HStack {
                                    SelfStoryImageView()
                                        .onTapGesture {
                                            if let user = authViewModel.currentUser {
                                                if !UserHelper.isUserPro(user.pro) {
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
                            
                            TipView(TipNewVersion156())
                                .padding(.trailing, 10)
                            
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
                        }
                        .padding(.horizontal)
                        .padding(.top, 5)
                        .cornerRadius(15)
                    }
                    .refreshable {
                        authViewModel.fetchAllUsers()
                        updateSearch()
                    }
                }
            } // ZStack
            .onAppear {
                self.searchViewModel.authViewModel = authViewModel
                self.searchViewModel.chipArray = viewModel.chipArray
                self.extraSkillsList = searchViewModel.skills.map { $0.name }
                updateSearch()
                Firestore.firestore().collection("admin").document("system").getDocument { (document, error) in
                    if let document = document, document.exists {
                        systemMessage = document.get("showHomeAlert") as? String
                    } else {
                        print("error while loading admin doc: \(error?.localizedDescription ?? "No error description")")
                    }
                }
            }
            .onChange(of: selectedValue) { _, _ in
                updateSearch()
            }
        }
        .navigationDestination(isPresented: $showProfileView) {
            ProfileView(user: profileUser ?? User())
                .toolbar(.hidden, for: .tabBar)
        }
    }
    
    func updateSearch(){
        if isEditSettings {
            searchViewModel.isLearning = selectedValue == .learningsSkills ? true : false
            searchViewModel.fetchUsers()
        } else {
            if !authViewModel.isLoading {
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
    
    enum SearchType: String, CaseIterable, Identifiable {
        case learningsSkills = "Learning skills"
        case selfSkills = "My skills"
        
        var id: Self { self }
    }
}

struct HeaderMainView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var callManager: CallManager
    
    @State private var showTopView = false
    
    var body: some View {
        VStack(spacing: 5) {
            if showTopView {
                CallTopView()
            }
            
            HStack {
                if let user = authViewModel.currentUser, UserHelper.isUserPro(user.pro) {
                    Image("logoPro")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 125)
                } else {
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 125)
                }
            }
            .padding(.bottom, 5)
            .padding(.horizontal, 15)
            .onChange(of: callManager.show) { _, _ in
                withAnimation {
                    showTopView = callManager.show
                }
            }
            
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
                
                NavigationLink(destination: NotificationsView()) {
                    Image(systemName: "bell")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20)
                }
            }
            
            Divider()
        }
        .padding(.horizontal)
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
                    } else if UserHelper.isUserPro(u.pro), let data = u.proData, let status = data.first(where: { $0.hasPrefix("status:") }) {
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
                } else if UserHelper.isUserPro(u.pro), let data = u.proData, let status = data.first(where: { $0.hasPrefix("status:") }) {
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

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

#Preview {
    FeedMainView(extraSkillsList: [])
        .environmentObject(AuthViewModel.mock)
        .environmentObject(ChatViewModel.mock)
        .environmentObject(CallManager.mock)
}


struct TipNewVersion156: Tip {
    var title: Text {
        Text("New version 1.5.6")
    }
    
    var message: Text? {
        Text("🚀 Audio messages have been added to chats.\n🚀 Now you can close photos and videos with a swipe down in chats.")
    }
    
    var image: Image? {
        Image(systemName: "wand.and.stars")
            .symbolRenderingMode(.palette)
    }
}
