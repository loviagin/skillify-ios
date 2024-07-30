//
//  FeedMainView.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 19.12.2023.
//

import SwiftUI
import FirebaseFirestore

struct FeedMainView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var mViewModel: MessagesViewModel
    @State var showMessagesView: Bool = false
    @State var showProfileView: Bool = false
    @State private var selectedValue: SearchType = .learningsSkills
    @State private var isEditSettings = false
    @StateObject var viewModel = ChipsViewModel()
    @State var searchViewModel = SearchViewModel(chipArray: [])
    
    @State var extraSkillsList: [String]
    @State private var selectedSkill: String = "Graphic Design"
    @State var isFavorite: Bool = false
    @State var proViewShow = false
    @State var profileViewShow = false
    
    @State var count = 0
    @State var profileUser: User?
    @State private var systemMessage: String? = nil
    @State private var tip1Show = UserDefaults.standard.bool(forKey: "tipFeedMainForSelfSkills") != true
    
    var body: some View {
        NavigationStack {
            ZStack{
                VStack {
                    HeaderMainView(showMessagesView: $showMessagesView, count: $count)
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
                                            NavigationLink(destination: ProfileView(showProfile: $showProfileView, user: user)) {
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
                                    ProfileView(showProfile: $showProfileView, user: authViewModel.currentUser!)
                                        .toolbar(.hidden, for: .navigationBar)
                                }
                            }
                            if tip1Show {
                                HStack {
                                    Text("You can add your skills and skills you wanna learn in Account tab")
                                        .padding()
                                    Spacer()
                                    Button {
                                        tip1Show = false
                                        UserDefaults.standard.setValue(true, forKey: "tipFeedMainForSelfSkills")
                                    } label: {
                                        Image(systemName: "xmark")
                                    }
                                    .padding(.trailing)
                                }
                                .frame(maxWidth: .infinity)
                                .background(.lGray)
                                .cornerRadius(15)
                                .padding([.trailing, .top], 10)
                            }
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
                                //                            if !authViewModel.isLoading {
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
                                        .onChange(of: selectedSkill) { _ in
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
                chechDestination()
                Firestore.firestore().collection("admin").document("system").getDocument { (document, error) in
                    if let document = document, document.exists {
                        systemMessage = document.get("showHomeAlert") as? String
                    } else {
                        print("error while loading admin doc: \(error?.localizedDescription ?? "No error description")")
                    }
                }
            }
            .onChange(of: authViewModel.destination) { _ in
                chechDestination()
            }
            .onChange(of: mViewModel.countUnread) { _ in
                count = mViewModel.countUnread
            }
            .onChange(of: selectedValue) { _ in
                updateSearch()
            }
            .gesture(DragGesture().onEnded { value in
                if value.translation.width < 0 { // Свайп влево
                    showMessagesView = true
                }
            })
        }
        .navigationDestination(isPresented: $showMessagesView, destination: { MessagesView(showChats: $showMessagesView) })
        .navigationDestination(isPresented: $showProfileView, destination: {
            if let user = profileUser {
                ProfileView(showProfile: $showProfileView, user: user)
                    .toolbar(.hidden, for: .tabBar)
                    .onDisappear {
                        profileUser = nil
                        showProfileView = false
                        authViewModel.destination = nil
                    }
            }
        })
    }
    
    func chechDestination() {
        if let destination = authViewModel.destination {
            let dest = destination.components(separatedBy: "/").first
            if dest == "m" {
                DispatchQueue.main.async {
                    showMessagesView = true
                }
            } else if destination.contains("@") {
                loadUser(String(destination.components(separatedBy: "@").last ?? "")) { error in
                    if let error {
                        print(error)
                    } else {
                        showProfileView = true
                    }
                }
            }
        }
    }
    
    func loadUser(_ user: String, completion: @escaping (String?) -> Void) {
        Firestore.firestore().collection("users").document(user).getDocument { snap, error in
            if let error {
                completion(error.localizedDescription)
            } else {
                self.profileUser = try? snap?.data(as: User.self)
                completion(nil)
            }
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
    @Binding var showMessagesView: Bool
    @EnvironmentObject var authViewModel: AuthViewModel
    @Binding var count: Int
    
    var body: some View {
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
                self.showMessagesView = true
            } label: {
                Image(systemName: "message")
                    .resizable()
                    .foregroundColor(.primary)
                    .scaledToFit()
                    .frame(width: 25, height: 25)
                    .overlay(
                        // Проверяем, есть ли непрочитанные сообщения и применяем логику сокращения
                        count > 0 ? Text(count <= 9 ? "\(count)" : "9+")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .frame(width: 20, height: 20)
                            .background(Color.red)
                            .clipShape(Circle())
                            .offset(x: 10, y: -10) : nil,
                        alignment: .topTrailing
                    )
            }
        }
        .padding(.bottom, 5)
        .padding(.horizontal, 15)
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
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                    } placeholder: {
                        Rectangle()
//                            .resizable()
//                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.white.opacity(0.4))
                            .padding(.trailing, 10)
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
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
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                    } placeholder: {
                        Rectangle()
//                            .resizable()
//                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.white.opacity(0.4))
                            .padding(.trailing, 10)
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
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
                    NavigationLink(destination: ProfileView(showProfile: $showProfile, user: user)) {
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
        .environmentObject(MessagesViewModel.mock)
}
