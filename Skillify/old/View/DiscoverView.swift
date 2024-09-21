//
//  DiscoverView.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 19.12.2023.
//
import SwiftUI
import Combine
import FirebaseFirestore

struct DiscoverView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject var viewModel = UsersViewModel()
    @StateObject var activeSkillManager = ActiveSkillManager()
    
    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    @State private var selectedPicture = 0
    @State private var pictures: [String] = []
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 125)
                        .padding(.top, 5)

                    Spacer()
                    NavigationLink(destination: FavoritesView()) {
                        Image(systemName: "star.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 25)
                            .foregroundColor(.brandBlue)
                    }
                }
                .padding(.bottom, 5)
                .padding(.horizontal, 15)
                ScrollView {
                    NavigationLink(
                        destination: UsersSearchView()
                    ) {
                        Text("Search users, skills...")
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: 35, alignment: .leading)
                            .background(.lGray)
                            .foregroundColor(.gray)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                    
                    HStack {
//                        Spacer()
                        Text("Popular skills ")
                            .padding()
                        Spacer()
                        NavigationLink(destination: UsersSearchView(textSearch: "Design")) {
                            Text("Design")
                                .padding(10)
                                .background(.lGray)
                                .cornerRadius(15)
                        }
                        Spacer()

                        NavigationLink(destination: UsersSearchView(textSearch: "Cooking")) {
                            Text("Cooking")
                                .padding(10)
                                .background(.lGray)
                                .cornerRadius(15)
                        }                        
                        Spacer()

                    }                    
                    .padding(.top, 10)

                    HStack {
                        Spacer()
                        NavigationLink(destination: UsersSearchView(textSearch: "Programming")) {
                            Text("Programming")
                                .padding(10)
                                .background(.lGray)
                                .cornerRadius(15)
                        }
                        Spacer()

                        NavigationLink(destination: UsersSearchView(textSearch: "Drum playing")) {
                            Text("Drum playing")
                                .padding(10)
                                .background(.lGray)
                                .cornerRadius(15)
                        }
                        Spacer()
                    }
                    
                    if !pictures.isEmpty {
                        GeometryReader { geometry in
                            TabView(selection: $selectedPicture) {
                                ForEach(pictures.indices, id: \.self) { index in
                                    AsyncImage(url: URL(string: pictures[index])) { phase in
                                        if let image = phase.image {
                                            image
                                                .resizable()
                                                .scaledToFit() // Используем scaledToFit для предотвращения обрезки
                                                .frame(width: geometry.size.width - 40, height: geometry.size.height)
                                                .clipShape(RoundedRectangle(cornerRadius: 20)) // Добавляем закругление углов
                                                .padding(.horizontal, 20) // Добавляем горизонтальные отступы
                                        } else if phase.error != nil {
                                            Color.red // Или любой другой индикатор ошибки
                                                .frame(width: geometry.size.width - 40, height: geometry.size.height)
                                                .clipShape(RoundedRectangle(cornerRadius: 20)) // Добавляем закругление углов
                                                .padding(.horizontal, 20) // Добавляем горизонтальные отступы
                                        } else {
                                            Color.gray // Или любой другой индикатор загрузки
                                                .frame(width: geometry.size.width - 40, height: geometry.size.height)
                                                .clipShape(RoundedRectangle(cornerRadius: 20)) // Добавляем закругление углов
                                                .padding(.horizontal, 20) // Добавляем горизонтальные отступы
                                        }
                                    }
                                    .tag(index)
                                }
                            }
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always)) // Включаем индикаторы точек
                            .frame(height: geometry.size.height)
                            .onReceive(timer) { _ in
                                withAnimation {
                                    selectedPicture = (selectedPicture + 1) % pictures.count // Переключаем на следующий слайд
                                }
                            }
                        }
                        .frame(height: 120) // Увеличиваем высоту для лучшего отображения
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("All users")
//                            .padding()

                        ForEach(viewModel.users) { user in
                            UserCardView(user: user,
                                         authViewModel: authViewModel, activeSkillManager: activeSkillManager, id: (authViewModel.currentUser?.id ?? ""))
                            .foregroundColor(.primary)
                        }
                    }
                    .padding()
                }
                .onAppear {
                    viewModel.currentUser = authViewModel.currentUser
                    viewModel.loadUsers()
                    Firestore.firestore().collection("admin").document("messages").getDocument { doc, error in
                        if error != nil {
                            print("error while load admin")
                        } else {
                            self.pictures = doc?.get("posts") as? [String] ?? []
                        }
                    }
                }
            }
        }
    }
}

struct UserCardView: View {
    @StateObject var viewModel: SkillsViewModel
    @ObservedObject var activeSkillManager: ActiveSkillManager
    var user: User
    let id: String
//    @State var showProfile = false
    
    init(user: User, authViewModel: AuthViewModel, activeSkillManager: ActiveSkillManager, id: String) {
        self.user = user
        self.activeSkillManager = activeSkillManager
        self.id = id
        
        // Использование временной переменной для инициализации viewModel
        let tempViewModel = SkillsViewModel(authViewModel: authViewModel)
        self._viewModel = StateObject(wrappedValue: tempViewModel)
    }
    
    var body: some View {
        NavigationLink(destination: ProfileView(/*showProfile: $showProfile, */user: user)) {
            HStack {
                Avatar2View(avatarUrl: user.urlAvatar, size: 70, maxHeight: 70, maxWidth: 70)
                VStack(alignment: .leading) {
                    Text("\(user.first_name) \(user.last_name)")
                        .font(.headline)
                        .lineLimit(1)
                    if !user.bio.isEmpty {
                        Text(user.bio)
                            .font(.subheadline)
                            .multilineTextAlignment(.leading)
                            .foregroundColor(.gray)
                    }
                    if user.selfSkills.count > 0 {
                        Text("User's skills: ")
                            .font(.callout)
                        
                        HStack {
                            ForEach(user.selfSkills, id: \.self) { skill in
                                let skillID = "\(user.id)-\(skill.name)"
                                SkillPopoverView(skill: skill,
                                                 skillID: skillID,
                                                 viewModel: viewModel,
                                                 activeSkillManager: activeSkillManager)
                            }
                        }
                    }
                    
                    if user.learningSkills.count > 0 {
                        Text("Learning skills: ")
                            .font(.callout)
                        
                        HStack {
                            ForEach(user.learningSkills, id: \.self) { skill in
                                let skillID = "\(user.id)-\(skill.name)"
                                SkillPopoverView(skill: skill,
                                                 skillID: skillID,
                                                 viewModel: viewModel,
                                                 activeSkillManager: activeSkillManager)
                            }
                        }
                    }
                }
                .padding(.leading, 10)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.background)
            .cornerRadius(15)
            .shadow(color: .gray, radius: 5)
        }
    }
}

struct SkillPopoverView: View {
    var skill: Skill
    var skillID: String
    var viewModel: SkillsViewModel
    @ObservedObject var activeSkillManager: ActiveSkillManager
    
    var body: some View {
        if let skillIndex = viewModel.skills.firstIndex(where: { $0.name == skill.name }) {
            let iconName = viewModel.skills[skillIndex].iconName
            Image(systemName: iconName!)
                .frame(width: 25, height: 25)
                .padding(5)
                .background(.blue)
                .foregroundColor(.white)
                .clipShape(Circle())
                .onTapGesture {
                    activeSkillManager.activeSkillID = (activeSkillManager.activeSkillID == skillID) ? nil : skillID
                }
                .overlay(
                    VStack {
                        if activeSkillManager.activeSkillID == skillID {
                            PopoverContentView(skillName: skill.name)
                                .frame(width: 200, height: 50)
                                .fixedSize(horizontal: false, vertical: true)
                                .offset(y: -60)
                        }
                    }, alignment: .top
                )
        }
    }
}

struct PopoverContentView: View {
    var skillName: String
    
    var body: some View {
        VStack(spacing: 0) {
            Text(skillName)
                .font(.headline)
                .padding(.vertical, 5)
                .padding(.horizontal, 8)
                .frame(width: 200, height: 50)
                .background(.background)
                .foregroundColor(.primary)
                .cornerRadius(10)
                .shadow(radius: 5)
            //                .offset(y: -50)
            Triangle()
                .fill(.background)
                .frame(width: 20, height: 10)
        }
    }
}

class ActiveSkillManager: ObservableObject {
    @Published var activeSkillID: String?
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        
        return path
    }
}

//#Preview {
//    DiscoverView()
//}
