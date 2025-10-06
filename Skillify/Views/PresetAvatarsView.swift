//
//  PresetAvatarsView.swift
//  Skillify
//
//  Created by Ilia Loviagin on 10/6/25.
//

import SwiftUI

struct PresetAvatarsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedAvatar: String?
    
    var body: some View {
        ScrollView {
            Text("Choose your avatar")
                .font(.title)
                .bold()
                .padding(30)
            
            LazyVGrid(columns: [GridItem(.fixed(120)), GridItem(.fixed(120)), GridItem(.fixed(120))], spacing: 20) {
                ForEach(Avatars.avatars, id: \.self) { avatar in
                    Image(avatar)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 90, height: 90)
                        .padding([.top, .leading, .trailing])
                        .background(.newBlue.opacity(0.5))
                        .clipShape(Circle())
                        .onTapGesture {
                            selectedAvatar = avatar
                            dismiss()
                        }
                    
                }
            }
        }
        .scrollIndicators(.never)
    }
}

#Preview {
    PresetAvatarsView(selectedAvatar: .constant(nil))
}
