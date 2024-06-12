////
////  SkillsSelectionView.swift
////  Skillify App
////
////  Created by Ilia Loviagin on 11.02.2024.
////
//
//import SwiftUI
//
//struct SkillsSelectionView: View {
//    @State private var searchText = ""
//    @State private var selectedSkills: [String] = []
//    var skills: [String]
//
//    var filteredSkills: [String] {
//        skills.filter { skill in
//            searchText.isEmpty || skill.localizedCaseInsensitiveContains(searchText)
//        }
//    }
//
//    var body: some View {
//        VStack {
//            TextField("Введите навык...", text: $searchText)
//                .padding()
//                .border(Color.gray, width: 1)
//
//            List(filteredSkills, id: \.self) { skill in
//                Button(action: {
//                    // Добавляем или удаляем навык из списка выбранных
//                    if selectedSkills.contains(skill) {
//                        selectedSkills.removeAll { $0 == skill }
//                    } else {
//                        selectedSkills.append(skill)
//                    }
//                }) {
//                    HStack {
//                        Text(skill)
//                        Spacer()
//                        if selectedSkills.contains(skill) {
//                            Image(systemName: "checkmark")
//                        }
//                    }
//                }
//            }
//
//            // Отображаем выбранные навыки
//            Text("Выбранные навыки: \(selectedSkills.joined(separator: ", "))")
//                .padding()
//        }
//        .padding()
//    }
//}
//
//#Preview {
//    SkillsSelectionView(skills: [])
//}
