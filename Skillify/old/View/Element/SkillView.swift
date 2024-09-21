//
//  SkillView.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 19.12.2023.
//
import SwiftUI

struct SkillView: View {
    var imageName: String
    var textSkill: String
    @Binding var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: imageName)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.primary)
                    .frame(width: 20, height: 20)
                Text(textSkill)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
            .cornerRadius(15)
        }
    }
}


//#Preview {
//    SkillView(imageName: "qrcode", textSkill: "Programming", isSelected: false, action: {})
//}
