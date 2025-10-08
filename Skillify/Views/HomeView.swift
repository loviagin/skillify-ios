//
//  HomeView.swift
//  Skillify
//
//  Created by Ilia Loviagin on 10/5/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var viewModel: AuthViewModel
    @State private var selectedTab: Tab = .wantToLearn
    @State private var selectedWantToLearnSkills: Set<String> = []
    @State private var selectedWantToTeachSkills: Set<String> = []
    @State private var navigationPath = NavigationPath()
    
    // Mock data для демонстрации (позже можно заменить на реальные данные)
    private let topUsers: [AppUser] = [
        .init(id: "cejwinwij", authUserId: "wenf", roles: [], createdAt: Date(), updatedAt: Date()),
        .init(id: "cejwifwefenwij", authUserId: "wenf", roles: [], createdAt: Date(), updatedAt: Date()),
        .init(id: "cejwinfwwwwij", authUserId: "wenf", roles: [], createdAt: Date(), updatedAt: Date()),
        .init(id: "cejwindfewij", authUserId: "wenf", roles: [], createdAt: Date(), updatedAt: Date()),
        .init(id: "cejwiwqefdcdbf22nwij", authUserId: "wenf", roles: [], createdAt: Date(), updatedAt: Date()),
    ]
    
    // Вычисляемые свойства для навыков пользователя
    private var wantToLearnSkills: [UserSkill] {
        viewModel.appUser?.desiredSkills ?? []
    }
    
    private var wantToTeachSkills: [UserSkill] {
        viewModel.appUser?.ownedSkills ?? []
    }
    
    private let featuredUsers = [
        FeaturedUser(
            id: "1",
            name: "Harry McWilliams",
            bio: "I'm average height",
            avatarName: "avatar3",
            skills: ["Programming", "Marketing"],
            skillIcons: ["💻", "📢", "🎯", "🌍", "🏋️"]
        ),
        FeaturedUser(
            id: "2",
            name: "Aline Jolith",
            bio: "I'm UX designer",
            avatarName: "avatar2",
            skills: ["Graphic Design", "Photography"],
            skillIcons: ["🎨", "📷", "✏️", "🌈", "🖌️"]
        ),
        FeaturedUser(
            id: "3",
            name: "John Doe",
            bio: "Developer",
            avatarName: "avatar1",
            skills: ["Programming", "Leadership"],
            skillIcons: ["💻", "🚀", "⚡", "🎯", "🏆"]
        ),
        FeaturedUser(
            id: "4",
            name: "Jane Smith",
            bio: "Content Creator",
            avatarName: "avatar4",
            skills: ["Writing", "Marketing"],
            skillIcons: ["✍️", "📢", "📚", "💡", "🎬"]
        )
    ]
    
    // Вычисляемые свойства
    private var currentSkills: [UserSkill] {
        selectedTab == .wantToLearn ? wantToLearnSkills : wantToTeachSkills
    }
    
    private var currentSelectedSkills: Set<String> {
        selectedTab == .wantToLearn ? selectedWantToLearnSkills : selectedWantToTeachSkills
    }
    
    private var hasSelectedSkills: Bool {
        !currentSelectedSkills.isEmpty
    }
    
    private var filteredUsers: [FeaturedUser] {
        // Показываем всех пользователей, так как у нас нет реальных данных других пользователей
        return featuredUsers
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    headerView
                        .padding(.horizontal, 20)
                    
                    // Top Users Section
                    topUsersSection
                    
                    // Skills Toggle
                    skillsToggle
                    
                    // Learning Skills Card
                    learningSkillsCard
                    
                    // Featured Users
                    featuredUsersSection
                }
                .padding(.top, 10)
            }
            .onAppear {
                // Обновляем профиль при возврате на главный экран
                Task {
                    await viewModel.userViewModel.fetchProfile()
                }
            }
            .navigationDestination(for: String.self) { destination in
                switch destination {
                case "addDesiredSkills":
                    LearningSkillsViewWrapper(
                        initialSkills: viewModel.appUser?.desiredSkills ?? [],
                        mySkills: viewModel.appUser?.ownedSkills ?? [],
                        onComplete: { updatedSkills in
                            await viewModel.updateUserSkills(
                                desiredSkills: updatedSkills
                            )
                            await viewModel.userViewModel.fetchProfile()
                        }
                    )
                case "addOwnedSkills":
                    MySkillsViewWrapper(
                        initialSkills: viewModel.appUser?.ownedSkills ?? [],
                        onComplete: { updatedSkills in
                            await viewModel.updateUserSkills(
                                ownedSkills: updatedSkills
                            )
                            await viewModel.userViewModel.fetchProfile()
                        }
                    )
                default:
                    EmptyView()
                }
            }
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hi, \(viewModel.appUser?.name ?? viewModel.userViewModel.currentUser?.name ?? "User")")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.primary)
                
                //MARK: - Add Ai Assistant
                Text("What do you want to learn today?")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button {
                
            } label: {
                Image(systemName: "bell")
                    .font(.system(size: 24))
                    .foregroundColor(.primary)
            }
        }
    }
    
    // MARK: - Top Users Section
    private var topUsersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Top Users")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("View all") {
                    // Action
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.blue)
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(topUsers) { user in
                        VStack {
                            ZStack(alignment: .bottomTrailing) {
                                AvatarView(avatarImage: .constant(nil), avatarUrl: .constant(user.avatarUrl), size: 80)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                user.isCurrentUser(viewModel.userViewModel.currentUser?.id) ? Color.blue : Color.clear,
                                                lineWidth: 3
                                            )
                                    )
                                    .padding(2)
                                
                                if user.isCurrentUser(viewModel.userViewModel.currentUser?.id) {
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 24, height: 24)
                                        .overlay(
                                            Image(systemName: "plus")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.white)
                                        )
                                }
                            }
                            
                            Text(user.name ?? "User")
                                .font(.system(size: 14))
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding(.leading, 20)
            }
        }
    }
    
    // MARK: - Skills Toggle
    private var skillsToggle: some View {
        HStack(spacing: 12) {
            ToggleButton(
                title: "Want to Learn",
                isSelected: selectedTab == .wantToLearn,
                isChecked: !selectedWantToLearnSkills.isEmpty
            ) {
                selectedTab = .wantToLearn
            }
            
            ToggleButton(
                title: "Want to Teach",
                isSelected: selectedTab == .wantToTeach,
                isChecked: !selectedWantToTeachSkills.isEmpty
            ) {
                selectedTab = .wantToTeach
            }
        }
        .background(
            LinearGradient(
                colors: [
                    .newBlue.opacity(0.2),
                    .newPink.opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        
    }
    
    // MARK: - Skills Card
    private var learningSkillsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            if currentSkills.isEmpty {
                Text("No skills selected")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                FlowLayout(spacing: 12) {
                    ForEach(currentSkills, id: \.id) { userSkill in
                        SkillTag(
                            skill: userSkill.skill,
                            isSelected: currentSelectedSkills.contains(userSkill.skill.name)
                        ) {
                            toggleSkillSelection(userSkill.skill.name)
                        }
                    }
                    
                    // Кнопка добавления навыка
                    Button(action: {
                        // Навигация к соответствующему экрану редактирования навыков
                        if selectedTab == .wantToLearn {
                            // Навигация к экрану добавления желаемых навыков
                            navigationPath.append("addDesiredSkills")
                        } else {
                            // Навигация к экрану добавления навыков для обучения
                            navigationPath.append("addOwnedSkills")
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.system(size: 16))
                            Text("Add")
                                .font(.system(size: 15, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.4, green: 0.55, blue: 0.85),
                                    Color(red: 0.6, green: 0.45, blue: 0.85),
                                    Color(red: 0.85, green: 0.5, blue: 0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .opacity(0.8)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Helper Methods
    private func toggleSkillSelection(_ skill: String) {
        if selectedTab == .wantToLearn {
            if selectedWantToLearnSkills.contains(skill) {
                selectedWantToLearnSkills.remove(skill)
            } else {
                selectedWantToLearnSkills.insert(skill)
            }
        } else {
            if selectedWantToTeachSkills.contains(skill) {
                selectedWantToTeachSkills.remove(skill)
            } else {
                selectedWantToTeachSkills.insert(skill)
            }
        }
    }
    
    // MARK: - Featured Users Section
    private var featuredUsersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                ForEach(filteredUsers) { user in
                    FeaturedUserCard(user: user)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    enum Tab {
        case wantToLearn
        case wantToTeach
    }
}

struct ToggleButton: View {
    let title: String
    let isSelected: Bool
    var isChecked: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                
                if isChecked {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                }
            }
            .foregroundColor(isSelected ? .white : .primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? .newBlue : Color.clear)
            .cornerRadius(12)
        }
    }
}

struct SkillTag: View {
    let skill: Skill
    var isSelected: Bool = false
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button(action: {
            action?()
        }) {
            HStack(spacing: 8) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                } else {
                    Image(systemName: skill.iconName ?? "star.fill")
                        .font(.system(size: 16))
                }
                Text(skill.name)
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: isSelected ? [
                        Color(red: 0.2, green: 0.4, blue: 0.8),
                        Color(red: 0.3, green: 0.25, blue: 0.7),
                        Color(red: 0.5, green: 0.3, blue: 0.6)
                    ] : [
                        Color(red: 0.4, green: 0.55, blue: 0.85),
                        Color(red: 0.6, green: 0.45, blue: 0.85),
                        Color(red: 0.85, green: 0.5, blue: 0.7)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .opacity(isSelected ? 1.0 : 0.8)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.white.opacity(0.5) : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FeaturedUser: Identifiable {
    let id: String
    let name: String
    let bio: String
    let avatarName: String
    let skills: [String]
    let skillIcons: [String]
}

struct FeaturedUserCard: View {
    let user: FeaturedUser
    
    var body: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(user.avatarName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                )
            
            Text(user.name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            Text(user.bio)
                .font(.system(size: 13))
                .foregroundColor(.gray)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("User skills:")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                
                HStack(spacing: 8) {
                    ForEach(user.skillIcons.prefix(5), id: \.self) { icon in
                        Text(icon)
                            .font(.system(size: 20))
                    }
                }
                
                if user.skillIcons.count > 5 {
                    HStack(spacing: 8) {
                        ForEach(user.skillIcons.dropFirst(5).prefix(3), id: \.self) { icon in
                            Text(icon)
                                .font(.system(size: 20))
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.08))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

struct NavItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 24))
            Text(title)
                .font(.system(size: 10))
        }
        .foregroundColor(isSelected ? .blue : .gray)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var frames: [CGRect] = []
        var size: CGSize = .zero
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(x: x, y: y, width: size.width, height: size.height))
                
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

// MARK: - Wrapper Views for Skill Editing
struct LearningSkillsViewWrapper: View {
    let initialSkills: [UserSkill]
    let mySkills: [UserSkill]
    let onComplete: ([UserSkill]) async -> Void
    
    @State private var selectedSkills: [UserSkill]
    @State private var isLoading = false
    @Environment(\.dismiss) private var dismiss
    
    init(initialSkills: [UserSkill], mySkills: [UserSkill], onComplete: @escaping ([UserSkill]) async -> Void) {
        self.initialSkills = initialSkills
        self.mySkills = mySkills
        self.onComplete = onComplete
        self._selectedSkills = State(initialValue: initialSkills)
    }
    
    var body: some View {
        LearningSkillsView(
            selectedSkills: $selectedSkills,
            mySkills: mySkills,
            isLoading: $isLoading,
            onComplete: {
                Task {
                    await onComplete(selectedSkills)
                    dismiss()
                }
            }, mode: .update
        )
        .toolbar(.hidden, for: .tabBar)
    }
}

struct MySkillsViewWrapper: View {
    let initialSkills: [UserSkill]
    let onComplete: ([UserSkill]) async -> Void
    
    @State private var selectedSkills: [UserSkill]
    @Environment(\.dismiss) private var dismiss
    
    init(initialSkills: [UserSkill], onComplete: @escaping ([UserSkill]) async -> Void) {
        self.initialSkills = initialSkills
        self.onComplete = onComplete
        self._selectedSkills = State(initialValue: initialSkills)
    }
    
    var body: some View {
        MySkillsView(
            selectedSkills: $selectedSkills,
            onContinue: {
                Task {
                    await onComplete(selectedSkills)
                    dismiss()
                }
            }, mode: .update
        )
        .toolbar(.hidden, for: .tabBar)
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthViewModel.mock)
}
