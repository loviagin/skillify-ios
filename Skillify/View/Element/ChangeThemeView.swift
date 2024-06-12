//
//  ChangeThemeView.swift
//  Skillify
//
//  Created by Ilia Loviagin on 6/10/24.
//

import SwiftUI

struct ChangeThemeView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State var userId: String
    
    var body: some View {
        VStack {
            Text("Choose your theme")
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack {
                ForEach(UserHelper.theme, id: \.self) { it in
                    Image(it)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .onTapGesture {
                            UserDefaults.standard.setValue(it, forKey: "chatTheme\(userId)")
                            UserDefaults.standard.synchronize()
                            dismiss()
                        }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
    }
}

#Preview {
    ChangeThemeView(userId: "")
}
