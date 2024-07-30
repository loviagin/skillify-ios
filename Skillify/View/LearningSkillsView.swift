//
//  LearningSkillsView.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 19.12.2023.
//

import SwiftUI

struct LearningSkillsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @StateObject var viewModel: LearningSkillsViewModel
    @State private var showToast = false
    @State private var showError: Bool = false
    @State private var isRegistration = true
    
    init(authViewModel: AuthViewModel, isRegistration: Bool = false) {
        self.isRegistration = isRegistration

        _viewModel = StateObject(wrappedValue: LearningSkillsViewModel(authViewModel: authViewModel))
    }
    
    var body: some View {
        VStack{
            VStack(alignment: .leading){
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100)
                Text("Choose up to 5 skills you wanna learn")
                Text("You have selected \(viewModel.skills.filter({ (($0.level?.isEmpty) != nil) }).count)")
                    .font(.caption2)
                if showError {
                    Text("You should choose at least 1 skill")
                        .font(.callout)
                        .foregroundStyle(.red)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            TextField("Search skill...", text: $viewModel.searchText)
                .padding(7)
                .padding(.horizontal, 25)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 8)
                        
                        if !viewModel.searchText.isEmpty {
                            Button(action: {
                                self.viewModel.searchText = ""
                            }) {
                                Image(systemName: "multiply.circle.fill")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 8)
                            }
                        }
                    }
                )
                .padding(.horizontal)
            List {
                ForEach(viewModel.filteredSkills.indices, id: \.self) { index in
                    VStack {
                        HStack {
                            Image(systemName: viewModel.filteredSkills[index].iconName ?? "circle.badge.questionmark")
                                .resizable()
                                .symbolRenderingMode(.multicolor)
                                .scaledToFit()
                                .frame(width: 25, height: 25)
                            Text(viewModel.filteredSkills[index].name)
                            Spacer()
                            if let level = viewModel.filteredSkills[index].level {
                                Text(level)
                                    .foregroundColor(.gray)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation {
                                viewModel.selectSkill(viewModel.filteredSkills[index])
                            }
                        }
                        if let originalIndex = viewModel.originalIndex(forFilteredIndex: index),
                           viewModel.skills[originalIndex].isSelected {
                            Picker("Select Level", selection: $viewModel.skills[originalIndex].level) {
                                if let skl = authViewModel.currentUser?.selfSkills.first(where: { $0.name == viewModel.skills[originalIndex].name }) {
                                    Text(skl.level ?? "Beginner").tag(skl.level as String?)
                                } else {
                                    Text("Beginner").tag("Beginner" as String?)
                                    Text("Intermediate").tag("Intermediate" as String?)
                                    Text("Advanced").tag("Advanced" as String?)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .onChange(of: viewModel.filteredSkills[index].level) { newValue in
                                if let newLevel = newValue {
                                    if newLevel != "" {
                                        let updatedSkill = Skill(name: viewModel.filteredSkills[index].name, level: newLevel)
                                        authViewModel.updateLSkill(updatedSkill)
                                    }
                                    // Скрываем плашку выбора уровня
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        viewModel.deselectSkill()
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .padding(.horizontal, 5)
            .padding(.vertical, 5)
            .onAppear {
                if let userSkills = authViewModel.currentUser?.learningSkills {
                    viewModel.updateSkills(with: userSkills)
                }
            }
            .navigationTitle("Learning skills")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(isRegistration)
            .toolbar(content: {
                if isRegistration {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            if !(authViewModel.currentUser?.learningSkills.isEmpty ?? true) {
                                dismiss()
                            } else {
                                showError = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    showError = false
                                }
                            }
                        } label: {
                            Text("Done")
                        }
                    }
                }
            })
        }
    }
}

#Preview {
    SelfSkillsView(authViewModel: AuthViewModel.mock)
        .environmentObject(AuthViewModel.mock)
}
