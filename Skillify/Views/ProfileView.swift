//
//  ProfileView.swift
//  Skillify
//
//  Created by Ilia Loviagin on 10/9/25.
//

import SwiftUI

struct ProfileView: View {
    @State private var isMySkillsExpanded = true
    @State private var isLearningExpanded = true
    @State private var isSubscribed = false
    @State private var isSubscribing = false
    
    @State var user: AppUser
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    private var userViewModel: UserViewModel {
        authViewModel.userViewModel
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Profile Header
                profileHeaderView
                
                // User Info
                userInfoView
                
                // Action Buttons
                if !user.isCurrentUser(userViewModel.currentUser?.id) {
                    actionButtonsView
                }
                
                // My Skills Section
                mySkillsSection
                
                // Learning Section
                learningSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .background(Color.gray.opacity(0.05))
            .onAppear {
                print("👤 ProfileView appeared for user: \(user.id) - \(user.name)")
                print("👤 Current subscribers count: \(user.subscribersCount)")
                print("👤 Current subscriptions count: \(user.subscriptionsCount)")
                checkSubscriptionStatus()
                // Обновляем данные пользователя с сервера при первом появлении
                Task {
                    await refreshUserData()
                }
            }
    }
    
    // MARK: - Profile Header
    private var profileHeaderView: some View {
        VStack(spacing: 0) {
            // Background Banner
            ZStack {
                // Gym background image placeholder
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Color.newPink.opacity(0.3), Color.newBlue.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 100)
                
                // Gym equipment icons
                HStack {
                    Image(systemName: "figure.run")
                        .font(.system(size: 40))
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.horizontal, 20)
            }
            
            // Profile Picture
            AvatarView(avatarImage: .constant(nil), avatarUrl: .constant(user.avatarUrl))
                .padding(.top, -60)
                .overlay(
                    Circle()
                        .stroke(Color.blue, lineWidth: user.subscription?.isActive ?? false ? 3 : 0)
                        .frame(width: 120, height: 120)
                        .padding(.top, -60)
                )
        }
    }
    
    // MARK: - User Info
    private var userInfoView: some View {
        VStack(spacing: 12) {
            // Name
            Text(user.name ?? "Unknown User")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            if let bio = user.bio, !bio.isEmpty {
                Text(bio)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            
            // Stats
            subscriptionStatsView
        }
    }
    
    // MARK: - Subscription Stats View
    private var subscriptionStatsView: some View {
        HStack(spacing: 0) {
            // Subscribers
            NavigationLink(destination: SubscriptionListView(user: user, initialTab: .subscribers)) {
                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.blue)
                        
                        Text("Subscribers")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    
                    Text(user.formattedSubscribersCount)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.blue.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Divider
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 1, height: 40)
                .padding(.horizontal, 8)
            
            // Subscriptions
            NavigationLink(destination: SubscriptionListView(user: user, initialTab: .subscriptions)) {
                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "person.badge.plus.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.green)
                        
                        Text("Following")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    
                    Text(user.formattedSubscriptionsCount)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.green.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.green.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 4)
    }
    
    private func statButton(title: String, subtitle: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Action Buttons
    private var actionButtonsView: some View {
        HStack(spacing: 16) {
            actionButton(icon: "message", action: {})
            actionButton(icon: isSubscribed ? "person.badge.minus" : "person.badge.plus", action: {
                toggleSubscription()
            })
            actionButton(icon: "phone", action: {})
            actionButton(icon: "video", action: {})
        }
    }
    
    private func actionButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(.secondary)
                .frame(width: 44, height: 44)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
        }
    }
    
    // MARK: - My Skills Section
    private var mySkillsSection: some View {
        VStack(spacing: 0) {
            // Header
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isMySkillsExpanded.toggle()
                }
            } label: {
                HStack {
                    Text("My Skills")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Image(systemName: isMySkillsExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            
            if isMySkillsExpanded {
                Divider()
                    .padding(.horizontal)
                
                VStack(spacing: 8) {
                    ForEach(user.ownedSkills) { userSkill in
                        skillRow(userSkill: userSkill, isLearning: false)
                    }
                }
                .padding()
            }
        }
        .background(Color.gray.opacity(0.08))
        .cornerRadius(16)
    }
    
    // MARK: - Learning Section
    private var learningSection: some View {
        VStack(spacing: 0) {
            // Header
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isLearningExpanded.toggle()
                }
            } label: {
                HStack {
                    Text("I Learning")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Image(systemName: isLearningExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            
            if isLearningExpanded {
                Divider()
                    .padding(.horizontal)
                
                VStack(spacing: 8) {
                    ForEach(user.desiredSkills) { userSkill in
                        skillRow(userSkill: userSkill, isLearning: true)
                    }
                }
                .padding()
            }
        }
        .background(Color.gray.opacity(0.08))
        .cornerRadius(16)
    }
    
    // MARK: - Skill Row
    private func skillRow(userSkill: UserSkill, isLearning: Bool) -> some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: userSkill.skill.iconName ?? "star.fill")
                .font(.system(size: 20))
                .foregroundStyle(.primary)
                .frame(width: 24, height: 24)
            
            // Skill Name
            Text(userSkill.skill.name)
                .font(.body)
                .foregroundStyle(.primary)
            
            Spacer()
            
            // Progress Dots
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(isLearning ? Color.gray.opacity(0.3) : (index < skillLevelToDots(userSkill.level) ? Color.blue : Color.gray.opacity(0.3)))
                        .frame(width: 8, height: 8)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func skillLevelToDots(_ level: SkillLevel?) -> Int {
        guard let level = level else { return 0 }
        switch level {
        case .bronze: return 1
        case .silver: return 2
        case .gold: return 3
        }
    }
    
    // MARK: - Subscription Logic
    private func toggleSubscription() {
        print("🔄 Toggle subscription called. Current state: \(isSubscribed)")
        guard !isSubscribing else {
            print("❌ Already subscribing, ignoring")
            return
        }
        
        isSubscribing = true
        print("⏳ Starting subscription process...")
        
        Task {
            do {
                if isSubscribed {
                    // Unfollow user
                    print("📤 Unfollowing user: \(user.id)")
                    let success = await unfollowUser()
                    print("📤 Unfollow result: \(success)")
                    if success {
                        await MainActor.run {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isSubscribed = false
                                user.subscribersCount = max(0, user.subscribersCount - 1)
                                print("✅ Updated subscribers count to: \(user.subscribersCount)")
                            }
                            showSubscriptionFeedback()
                        }
                    }
                } else {
                    // Follow user
                    print("📥 Following user: \(user.id)")
                    let success = await followUser()
                    print("📥 Follow result: \(success)")
                    if success {
                        await MainActor.run {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isSubscribed = true
                                user.subscribersCount += 1
                                print("✅ Updated subscribers count to: \(user.subscribersCount)")
                            }
                            showSubscriptionFeedback()
                            // Refresh user data from server
                            Task {
                                await refreshUserData()
                            }
                        }
                    }
                }
            } catch {
                print("❌ Subscription error: \(error)")
            }
            
            await MainActor.run {
                isSubscribing = false
                print("✅ Subscription process completed")
            }
        }
    }
    
    private func showSubscriptionFeedback() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Here you could add a toast notification or other UI feedback
        // For now, we'll just use haptic feedback
    }
    
    // MARK: - API Calls
    private func checkSubscriptionStatus() {
        print("🔍 Checking subscription status for user: \(user.id)")
        Task {
            let isFollowing = await userViewModel.checkIfFollowing(userId: user.id)
            print("🔍 Subscription status result: \(isFollowing)")
            await MainActor.run {
                self.isSubscribed = isFollowing
            }
        }
    }
    
    private func refreshUserData() async {
        print("🔄 Refreshing user data for: \(user.id)")
        if let updatedUser = await userViewModel.getUserProfile(userId: user.id) {
            await MainActor.run {
                self.user = updatedUser
                print("🔄 Updated user data - subscribers: \(updatedUser.subscribersCount), subscriptions: \(updatedUser.subscriptionsCount)")
            }
        } else {
            print("❌ Failed to refresh user data")
        }
    }
    
    private func followUser() async -> Bool {
        print("📥 Calling followUser API for user: \(user.id)")
        let result = await userViewModel.followUser(userId: user.id)
        print("📥 followUser API result: \(result)")
        return result
    }
    
    private func unfollowUser() async -> Bool {
        print("📤 Calling unfollowUser API for user: \(user.id)")
        let result = await userViewModel.unfollowUser(userId: user.id)
        print("📤 unfollowUser API result: \(result)")
        return result
    }
}

#Preview {
    NavigationStack {
        ProfileView(user: AppUser(
            id: "1",
            authUserId: "auth1",
            name: "Harry McWilliams",
            bio: "I'm average height",
            avatarUrl: "avatar1",
            roles: [],
            ownedSkills: [
                UserSkill(skill: Skill(id: "development", name: "Development", category: "Programming", iconName: "brain"), level: .silver),
                UserSkill(skill: Skill(id: "gym", name: "Fitness Gym", category: "Sports", iconName: "dumbbell.fill"), level: .gold),
                UserSkill(skill: Skill(id: "yoga", name: "Yoga", category: "Sports", iconName: "figure.mind.and.body"), level: .silver),
                UserSkill(skill: Skill(id: "painting", name: "Painting", category: "Creative", iconName: "paintpalette.fill"), level: .gold)
            ],
            desiredSkills: [
                UserSkill(skill: Skill(id: "sewing", name: "Sewing", category: "Crafts", iconName: "scissors"), level: nil),
                UserSkill(skill: Skill(id: "cooking", name: "Cooking", category: "Cooking", iconName: "frying.pan.fill"), level: nil)
            ],
            createdAt: Date(),
            updatedAt: Date(),
            subscribersCount: 10,
            subscriptionsCount: 10009
        ))
    }
}
