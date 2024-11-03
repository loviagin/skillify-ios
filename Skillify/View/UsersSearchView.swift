//
//  UsersSearchView.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 19.12.2023.
//

import SwiftUI

struct UsersSearchView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject var viewModel = UsersViewModel()
    @State private var selectedCategory: UsersViewModel.SearchCategory = .firstName
    @State var textSearch: String? = ""
    
    @FocusState private var isTextFieldFocused: Bool
    @StateObject var activeSkillManager = ActiveSkillManager() // Создание экземпляра
    
    var body: some View {
        VStack {
            TextField("Search", text: $viewModel.searchText)
                .padding()
                .focused($isTextFieldFocused)
                .onChange(of: viewModel.searchText) { _ in
                    viewModel.searchUsers(by: selectedCategory)
                }

            Picker("Search Category", selection: $selectedCategory) {
                ForEach(UsersViewModel.SearchCategory.allCases, id: \.self) { category in
                    Text(category.tabTitle).tag(category)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(viewModel.filteredUsers) { user in
                        UserCardView(user: user, authViewModel: authViewModel, activeSkillManager: activeSkillManager, id: authViewModel.currentUser!.id)
                            .foregroundColor(.primary)
                    }
                }
                .padding()
            }
            .onAppear() {
                self.viewModel.currentUser = authViewModel.currentUser
                self.viewModel.loadAllUsers()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if let ts = textSearch, !ts.isEmpty {
                        selectedCategory = .skill
                        viewModel.searchText = ts
                        viewModel.searchUsers(by: selectedCategory)
                    } else {
                        self.isTextFieldFocused = true
                    }
                }
            }
        }
        .onAppear {
            viewModel.searchUsers(by: selectedCategory)
        }
    }
}

#Preview {
    UsersSearchView()
}
