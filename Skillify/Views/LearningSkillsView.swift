//
//  SelectDesiredSkillsView.swift
//  Skillify
//
//  Created by Ilia Loviagin on 10/7/25.
//

import SwiftUI

struct LearningSkillsView: View {
    @Binding var selectedSkills: [UserSkill]
    var mySkills: [UserSkill]
    @Binding var isLoading: Bool
    var onComplete: () -> Void
    
    @State private var searchText: String = ""
    @State private var selectedCategory: String = "All"
    
    private let maxSkills = 5
    private let availableSkills = Skill.predefinedSkills
    
    private var categories: [String] {
        let cats = ["All"] + Set(availableSkills.map { $0.category }).sorted()
        return cats
    }
    
    private var filteredSkills: [Skill] {
        availableSkills.filter { skill in
            // Фильтруем навыки, которые уже владеем
            let notOwned = !mySkills.contains { $0.skill.id == skill.id }
            let matchesCategory = selectedCategory == "All" || skill.category == selectedCategory
            let matchesSearch = searchText.isEmpty || skill.name.localizedCaseInsensitiveContains(searchText)
            return notOwned && matchesCategory && matchesSearch
        }
    }
    
    private var groupedSkills: [String: [Skill]] {
        Dictionary(grouping: filteredSkills) { $0.category }
    }
    
    private var canComplete: Bool {
        selectedSkills.count > 0
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Skills to Learn")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Select up to \(maxSkills) skills you want to learn")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    // Skills counter
                    ZStack {
                        Circle()
                            .fill(selectedSkills.count >= maxSkills ? Color.newPink : Color.newBlue)
                            .frame(width: 50, height: 50)
                        
                        Text("\(selectedSkills.count)/\(maxSkills)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    
                    TextField("Search skills...", text: $searchText)
                        .textFieldStyle(.plain)
                    
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.08))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Category filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(categories, id: \.self) { category in
                            CategoryChip(
                                title: category,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .background(Color(UIColor.systemBackground))
                        
            // Skills grid
            ScrollView {
                LazyVStack(spacing: 20, pinnedViews: [.sectionHeaders]) {
                    // Selected skills section
                    if !selectedSkills.isEmpty {
                        Section {
                            // Natural wrapping chips layout
                            WrappingHStack(spacing: 12, lineSpacing: 12) {
                                ForEach(selectedSkills) { userSkill in
                                    DesiredSkillChip(
                                        skill: userSkill.skill,
                                        onRemove: {
                                            withAnimation {
                                                selectedSkills.removeAll { $0.id == userSkill.id }
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        } header: {
                            HStack {
                                Text("Selected Skills")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color(UIColor.systemBackground))
                        }
                    }
                    
                    // Available skills
                    Section {
                        LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
                            ForEach(groupedSkills.keys.sorted(), id: \.self) { category in
                                Section {
                                    let skills = groupedSkills[category] ?? []
                                    LazyVGrid(columns: [
                                        GridItem(.flexible()),
                                        GridItem(.flexible())
                                    ], spacing: 12) {
                                        ForEach(skills) { skill in
                                            SkillCard(
                                                skill: skill,
                                                isSelected: selectedSkills.contains { $0.skill.id == skill.id },
                                                isDisabled: selectedSkills.count >= maxSkills && !selectedSkills.contains { $0.skill.id == skill.id }
                                            ) {
                                                toggleSkill(skill)
                                            }
                                        }
                                    }
                                } header: {
                                    if selectedCategory == "All" {
                                        HStack {
                                            Text(category)
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(.secondary)
                                            Spacer()
                                        }
                                        .padding(.top, 8)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    } header: {
                        if !selectedSkills.isEmpty {
                            HStack {
                                Text("Available Skills")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color(UIColor.systemBackground))
                        }
                    }
                }
                .padding(.vertical)
            }
            
            // Complete button
            VStack(spacing: 0) {
                Divider()
                
                AppButton(
                    text: "Complete Registration",
                    background: .newPink,
                    isLoading: $isLoading
                ) {
                    onComplete()
                }
                .disabled(!canComplete)
                .opacity(canComplete ? 1.0 : 0.5)
                .padding()
            }
            .background(Color(UIColor.systemBackground))
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func toggleSkill(_ skill: Skill) {
        if let index = selectedSkills.firstIndex(where: { $0.skill.id == skill.id }) {
            withAnimation {
                selectedSkills.remove(at: index)
            }
        } else if selectedSkills.count < maxSkills {
            withAnimation {
                // Для желаемых навыков не указываем уровень
                selectedSkills.append(UserSkill(skill: skill, level: nil))
            }
        }
    }
}

#Preview {
    NavigationStack {
        LearningSkillsView(
            selectedSkills: .constant([]),
            mySkills: [],
            isLoading: .constant(false),
            onComplete: {}
        )
    }
}

