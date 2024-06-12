//
//  CoverChooserView.swift
//  Skillify
//
//  Created by Ilia Loviagin on 6/3/24.
//

import SwiftUI

struct CoverChooserView: View {
    @Binding var cover: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Text("Choose color for your profile")
            .font(.title3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
        ForEach(UserHelper.covers, id: \.self) { it in
            CoverItemView(color1: UserHelper.getColor1(it), color2: UserHelper.getColor2(it))
                .onTapGesture {
                    cover = it
                    dismiss()
                }
        }
        DismissButton()
            .padding([.horizontal, .top], 5)
    }
}

struct CoverItemView: View {
    var color1: Color
    var color2: Color
    
    var body: some View {
        Rectangle()
            .fill(LinearGradient(
                gradient: Gradient(colors: [color1, color2]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .cornerRadius(15)
            .padding(.horizontal)
    }
}

#Preview {
    CoverChooserView(cover: .constant("cover:1"))
}
