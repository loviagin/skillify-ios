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
                            Text("Top Users")
                                .foregroundColor(.gray)
                                .font(.callout)
                                .padding(.leading, 10)
                                .padding(.bottom, 5)
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
                            
                            TipView(TipNewVersion151())
                                .padding(.trailing, 10)
                            
                            Text("Search by:")
                                .foregroundColor(.gray)
                                .font(.callout)
                                .padding([.leading, .top], 10)
                            HStack {
                                Picker("Выберите элемент", selection: $selectedValue) {
                                    ForEach(SearchType.allCases, id: \.self) { option in
                                        Text(option.rawValue).tag(option)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                
                                Spacer()
                                
                                Button {
                                    isEditSettings.toggle()
                                } label: {
                                    Image(systemName: isEditSettings ? "xmark" : "gearshape")
                                        .frame(width: 30, height: 30)
                                        .scaledToFit()
                                        .padding(.leading)
                                        .padding(.trailing, 5)
                                        .foregroundColor(.primary)
                                }
                            }
                            .padding(.bottom, 0)
                            .background(isEditSettings ? .lGray : .transparency)
                            .padding(.trailing, 10)
                            .cornerRadius(3)
                            
                            // Conditional content based on selectedValue
                            if !isEditSettings {
                                if selectedValue == .learningsSkills {
                                    if let list = authViewModel.currentUser?.learningSkills {
                                        if list.isEmpty {
                                            Text("It's default values. For customize it please go to the Account page")
                                                .font(.caption)
                                                .padding(.trailing, 5)
                                        }
                                    }
                                } else {
                                    if let list = authViewModel.currentUser?.selfSkills {
                                        if list.isEmpty {
                                            Text("It's default values. For customize it please go to the Account page")
                                                .font(.caption)
                                                .padding(.trailing, 5)
                                        }
                                    }
                                }
                                ChipContainerView(viewModel: viewModel, searchViewModel: searchViewModel)
                                    .frame(width: .infinity, height: 80)
                                    .padding(5)
                                    .background(.brandBlue.opacity(0.2))
                                    .cornerRadius(10)
                                    .padding(.trailing, 10)
                            } else {
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text("Choose any skill")
                                        Spacer()
                                        Picker("Extra skill", selection: $selectedSkill) {
                                            ForEach(extraSkillsList, id: \.self) { skill in
                                                Text(skill).tag(skill)
                                            }
                                        }
                                        .onChange(of: selectedSkill) { _, _ in
                                            searchViewModel.resetSelection()
                                            let index = searchViewModel.skills.firstIndex(where: {$0.name == selectedSkill})
                                            if let i = index {
                                                //                                        print("\(i)")
                                                searchViewModel.updateChipSelection(at: i)
                                            }
                                        }
                                    }
                                    
                                    Toggle(isOn: $isFavorite) {
                                        Text("Beta")
                                            .foregroundColor(.blue)
                                            .font(.caption2)
                                        Text("Show only favorites users")
                                    }
                                    .disabled(true)
                                }
                                .padding()
                                .background(.lGray)
                                .cornerRadius(15)
                            }
                            if let auth = authViewModel.currentUser {
                                UserSearchView(viewModel: searchViewModel, id: auth.id)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.leading, 10)
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
            ProfileView(/*showProfile: $showProfileView,*/user: profileUser ?? User())
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
            
            Spacer()
            
            Button {
                requestReview()
            } label: {
                Image(systemName: "star")
            }
        }
        .padding(.bottom, 5)
        .padding(.horizontal, 15)
        .onChange(of: callManager.show) { _, _ in
            withAnimation {
                showTopView = callManager.show
            }
        }
    }
    
    func requestReview() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return
        }
        SKStoreReviewController.requestReview(in: windowScene)
    }
}

struct SelfStoryImageView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    var body: some View {
        VStack(alignment: .center) {
            ZStack(alignment: .bottomTrailing) {
                if let user = authViewModel.currentUser, !UserHelper.isUserPro(user.pro) {
                    Image("add")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .clipped()
                        .clipShape(Circle())
                } else if UserHelper.avatars.contains(authViewModel.currentUser?.urlAvatar.split(separator: ":").first.map(String.init) ?? "") {
                    Image(authViewModel.currentUser!.urlAvatar.split(separator: ":").first.map(String.init) ?? "")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .padding(.top, 10)
                        .frame(width: 80, height: 80)
                        .background(Color.fromRGBAString(authViewModel.currentUser?.urlAvatar.split(separator: ":").last.map(String.init) ?? "") ?? .blue.opacity(0.4))
                        .clipShape(Circle())
                } else if let urlString = authViewModel.currentUser?.urlAvatar, !urlString.isEmpty, let url = URL(string: urlString) {
                    KFImage(url)
                        .resizable()
                        .placeholder {
                            Image("avatar1")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                                .clipped()
                        }
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .clipped()
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                    //                                            .padding(.bottom)
                }
                if let online = authViewModel.currentUser?.online, online == true {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .offset(x: -3, y: -3)
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
                if UserHelper.avatars.contains(u.urlAvatar.split(separator: ":").first.map(String.init) ?? "") {
                    Image(u.urlAvatar.split(separator: ":").first.map(String.init) ?? "")
                        .resizable()
                        .foregroundColor(.gray)
                        .aspectRatio(contentMode: .fill)
                        .padding(.top, 10)
                        .frame(width: 80, height: 80)
                        .background(Color.fromRGBAString(u.urlAvatar.split(separator: ":").last.map(String.init) ?? "") ?? .blue.opacity(0.4))
                        .clipShape(Circle())
                } else if let url = URL(string: u.urlAvatar) {
                    KFImage(url)
                        .resizable()
                        .placeholder {
                            Image("avatar1")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                                .clipped()
                        }
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .clipped()
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .foregroundColor(.gray)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                }
                if u.online ?? false {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .offset(x: -3, y: -3)
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
                        .foregroundColor(.brandBlue)
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
                    NavigationLink(destination: ProfileView(/*showProfile: $showProfile, */user: user)) {
                        SearchElementView(user: user)
                            .foregroundColor(Color.primary)
                    }
                }
            }
            .padding(.trailing, 10)
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
}


struct TipNewVersion151: Tip {
    var title: Text {
        Text("New version 1.5.1")
    }
    
    var message: Text? {
        Text("🚀 Change the chat color right from the top right.\n🚀 Open images in the chat and download them to the gallery.\n🚀 New emojies view - set and unset up to 3 on each message.\n🚀 Now if you remove the last message in a chat this chat will be deleting immediately")
    }
    
    var image: Image? {
        Image(systemName: "wand.and.stars")
            .symbolRenderingMode(.palette)
    }
}
