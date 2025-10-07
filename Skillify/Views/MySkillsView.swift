//
//  SelectOwnedSkillsView.swift
//  Skillify
//
//  Created by Ilia Loviagin on 10/7/25.
//

import SwiftUI

struct MySkillsView: View {
    @Binding var selectedSkills: [UserSkill]
    var onContinue: () -> Void
    
    @State private var searchText: String = ""
    @State private var selectedCategory: String = "All"
    @State private var showLevelPicker: Skill? = nil
    
    private let maxSkills = 5
    private let availableSkills = Skill.predefinedSkills
    
    private var categories: [String] {
        let cats = ["All"] + Set(availableSkills.map { $0.category }).sorted()
        return cats
    }
    
    private var filteredSkills: [Skill] {
        availableSkills.filter { skill in
            let matchesCategory = selectedCategory == "All" || skill.category == selectedCategory
            let matchesSearch = searchText.isEmpty || skill.name.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch
        }
    }
    
    private var groupedSkills: [String: [Skill]] {
        Dictionary(grouping: filteredSkills) { $0.category }
    }
    
    private var isValid: Bool {
        selectedSkills.count > 0
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your Skills")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Select up to \(maxSkills) skills you know")
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
                            VStack(spacing: 12) {
                                ForEach(selectedSkills) { userSkill in
                                    SelectedSkillCard(
                                        userSkill: userSkill,
                                        onRemove: {
                                            withAnimation {
                                                selectedSkills.removeAll { $0.id == userSkill.id }
                                            }
                                        },
                                        onLevelTap: {
                                            showLevelPicker = userSkill.skill
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
            
            // Continue button
            VStack(spacing: 0) {
                Divider()
                
                Button {
                    onContinue()
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isValid ? Color.newPink : Color.gray.opacity(0.3))
                        .cornerRadius(12)
                }
                .disabled(!isValid)
                .padding()
            }
            .background(Color(UIColor.systemBackground))
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $showLevelPicker) { skill in
            LevelPickerSheet(
                skill: skill,
                currentLevel: selectedSkills.first { $0.skill.id == skill.id }?.level,
                onSelect: { level in
                    print("🔵 Selected level: \(level.rawValue) for skill: \(skill.name)")
                    print("🔵 Current skills count: \(selectedSkills.count)")
                    
                    withAnimation {
                        if let index = selectedSkills.firstIndex(where: { $0.skill.id == skill.id }) {
                            // Обновляем существующий навык
                            print("🔵 Updating existing skill at index \(index)")
                            selectedSkills[index] = UserSkill(skill: skill, level: level)
                        } else {
                            // Добавляем новый навык с выбранным уровнем
                            print("🔵 Adding new skill")
                            selectedSkills.append(UserSkill(skill: skill, level: level))
                        }
                    }
                    
                    print("🔵 New skills count: \(selectedSkills.count)")
                }
            )
            .presentationDetents([.height(400)])
        }
    }
    
    private func toggleSkill(_ skill: Skill) {
        if let index = selectedSkills.firstIndex(where: { $0.skill.id == skill.id }) {
            withAnimation {
                selectedSkills.remove(at: index)
            }
        } else if selectedSkills.count < maxSkills {
            // Показываем выбор уровня для нового навыка
            showLevelPicker = skill
        }
    }
}

#Preview {
    NavigationStack {
        MySkillsView(
            selectedSkills: .constant([]),
            onContinue: {}
        )
    }
}

