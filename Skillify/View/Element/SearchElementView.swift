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
            Avatar2View(avatarUrl: user.urlAvatar, size: 70)
                .padding(.top)
                .padding(.bottom, 5)
            
            HStack(spacing: 5) {
                Text("\(user.first_name) \(user.last_name)")
                    .lineLimit(1)
                
                if let data = user.tags, data.contains("verified") {
                    Image("verify")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 15, height: 15)
                } else if let data = user.tags, data.contains("admin") {
                    Image("gold")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 15, height: 15)
                }
                
                if let status = user.proData?.first(where: { $0.hasPrefix("status:") }), UserHelper.isUserPro(user.proDate) {
                    Image(systemName: String(status.split(separator: ":").last ?? Substring(status)))
                        .resizable()
                        .scaledToFill()
                        .frame(width: 15, height: 15)
                        .foregroundColor(.brandBlue)
                }
            }
            
            Group {
                if user.bio.isEmpty {
                    Text("@\(user.nickname)")
                } else {
                    Text("\(user.bio)")
                }
            }
            .font(.caption)
            .lineLimit(1)
            
            Divider()
                .padding(.horizontal)
            
            Text("My skills:")
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 3)
            
            HStack {
                if !user.selfSkills.isEmpty {
                    ForEach(user.selfSkills) { s in
                        Image(systemName: "\(searchViewModel.skills[searchViewModel.skills.firstIndex(where: {$0.name == s.name})!].iconName ?? "checkmark.circle")")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .foregroundColor(.blue)
                    }
                } else {
                    Text("None")
                        .font(.caption)
                }
                
                Spacer()
            }
            .padding(.vertical, 3)
            
            Text("Learning skills:")
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 3)
            
            HStack {
                if !user.learningSkills.isEmpty {
                    ForEach(user.learningSkills) { s in
                        Image(systemName: "\(searchViewModel.skills[searchViewModel.skills.firstIndex(where: {$0.name == s.name})!].iconName ?? "checkmark.circle")")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .foregroundColor(.blue)
                    }
                } else {
                    Text("None")
                        .font(.caption)
                }
                
                Spacer()
            }
            .padding(.vertical, 3)
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 10)
        .background(.blue.opacity(0.1))
        .overlay(RoundedRectangle(cornerRadius: 8)
            .stroke(LinearGradient(colors: UserHelper.isUserPro(user.proDate) ? [.blue, .red] : [.blue.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing),
                    lineWidth: 3))
        .padding(3)
    }
}

#Preview {
    SearchElementView(user: User(id: "", first_name: "Ilia", last_name: "Lov", email: "", nickname: "", phone: "", birthday: Date()))
}
