//
//  SearchElementView.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 02.02.2024.
//

import SwiftUI

struct SearchElementView: View {
    var user: User
    var searchViewModel = SearchViewModel(chipArray: [])
    
    var body: some View {
        VStack {
            Avatar2View(avatarUrl: user.urlAvatar)
//                .background(.transparency)
                .padding(.top)
                .padding(.bottom, 5)
//                .padding()
//                .frame(width: 100, height: 100)
//                .scaledToFill()
            //                .cornerRadius(100)
            Text("\(user.first_name)")
//                .fontWeight(.bold)
//                .foregroundColor(.white)
                .lineLimit(1)
                .padding([.trailing, .leading], 5)
            Text("\(user.bio)")
//                .foregroundColor(.white)
                .font(.caption)
                .lineLimit(1)
                .padding([.trailing, .leading], 5)
            
            HStack() {
                Image(systemName: "star")
                    .frame(width: 25, height: 25)
                if !user.selfSkills.isEmpty {
                    if user.selfSkills.count > 3 {
                        Image(systemName: "\(searchViewModel.skills[searchViewModel.skills.firstIndex(where: {$0.name == user.selfSkills[0].name})!].iconName ?? "checkmark.circle")")
                            .frame(width: 25, height: 25)
                            .foregroundColor(.blue)
                        Image(systemName: "\(searchViewModel.skills[searchViewModel.skills.firstIndex(where: {$0.name == user.selfSkills[1].name})!].iconName ?? "checkmark.circle")")
                            .frame(width: 25, height: 25)
                            .foregroundColor(.blue)
                        Image(systemName: "\(searchViewModel.skills[searchViewModel.skills.firstIndex(where: {$0.name == user.selfSkills[2].name})!].iconName ?? "checkmark.circle")")
                            .frame(width: 25, height: 25)
                            .foregroundColor(.blue)
                        Text("+ more")
                            .font(.caption)
                        
                    } else {
                        ForEach(user.selfSkills) { s in
                            Image(systemName: "\(searchViewModel.skills[searchViewModel.skills.firstIndex(where: {$0.name == s.name})!].iconName ?? "checkmark.circle")")
                                .frame(width: 25, height: 25)
                                .foregroundColor(.blue)
                        }
                    }
                } else {
                    Text("None")
                        .font(.caption)
                }
                Spacer()
            }
            .padding([.bottom, .leading], 5)
//            .foregroundColor(.white)
            
            
            HStack() {
                Image(systemName: "lightbulb.min")
                    .frame(width: 25, height: 25)
                if !user.learningSkills.isEmpty {
                    if user.learningSkills.count > 3 {
                        Image(systemName: "\(searchViewModel.skills[searchViewModel.skills.firstIndex(where: {$0.name == user.learningSkills[0].name})!].iconName ?? "checkmark.circle")")
                            .frame(width: 25, height: 25)
                            .foregroundColor(.blue)
                        Image(systemName: "\(searchViewModel.skills[searchViewModel.skills.firstIndex(where: {$0.name == user.learningSkills[1].name})!].iconName ?? "checkmark.circle")")
                            .frame(width: 25, height: 25)
                            .foregroundColor(.blue)
                        Image(systemName: "\(searchViewModel.skills[searchViewModel.skills.firstIndex(where: {$0.name == user.learningSkills[2].name})!].iconName ?? "checkmark.circle")")
                            .frame(width: 25, height: 25)
                            .foregroundColor(.blue)
                        Text("+ more")
                            .font(.caption)
                        
                    } else {
                        ForEach(user.learningSkills) { s in
                            Image(systemName: "\(searchViewModel.skills[searchViewModel.skills.firstIndex(where: {$0.name == s.name})!].iconName ?? "checkmark.circle")")
                                .frame(width: 25, height: 25)
                                .foregroundColor(.blue)
                        }
                    }
                } else {
                    Text("None")
                        .font(.caption)
                }
                Spacer()
            }
            .padding(.leading, 5)
            .padding(.bottom)
            
        }
        .background(.linearGradient(colors: [.brandBlue.opacity(0.3), .redApp.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing))
        .cornerRadius(15)
//        .foregroundColor(.white)
        //        .onAppear {
        //            print("\(searchViewModel.skills[searchViewModel.skills.firstIndex(where: {$0.name == user.selfSkills[0].name})!].iconName ?? "checkmark.circle")")
        //        }
    }
}

#Preview {
    SearchElementView(user: User(id: "", first_name: "Ilia", last_name: "Lov", email: "", nickname: "", phone: "", birthday: Date()))
}
