//
//  StandardAvatarView.swift
//  Skillify
//
//  Created by Ilia Loviagin on 6/2/24.
//

import SwiftUI

struct StandardAvatarView: View {
    @Binding var isImageUploaded: Bool
    @Binding var colorAvatar: Color
    
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    var body: some View {
        Grid(alignment: .leading) {
            HStack {
                Text("Choose avatar you like")
                    .font(.title3)
                    .padding(.horizontal)
                Spacer()
                ColorPicker("", selection: $colorAvatar, supportsOpacity: false)
                    .frame(maxWidth: 100)
                    .padding()
            }
            LazyVGrid(columns:
                        [GridItem(.adaptive(minimum: 80, maximum: 200)),
                         GridItem(.adaptive(minimum: 80, maximum: 200)),
                         GridItem(.adaptive(minimum: 80, maximum: 200)),
                         GridItem(.adaptive(minimum: 80, maximum: 200))],
                      content: {
                ForEach(UserHelper.avatars, id: \.self) { it in
                    Image(it)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .padding(.top, 10)
                        .frame(width: 80, height: 80)
                        .padding(.horizontal)
                        .background(colorAvatar)
                        .clipShape(Circle())
                        .onTapGesture {
                            isImageUploaded = true
                            authViewModel.currentUser?.urlAvatar = it
                            presentationMode.wrappedValue.dismiss()
                        }
                }
            })
            DismissButton()
                .padding(.vertical)
        }
        .onChange(of: colorAvatar) { _ in
            isImageUploaded = true
        }
    }
}

#Preview {
    StandardAvatarView(isImageUploaded: .constant(false), colorAvatar: .constant(.blue.opacity(0.4)))
        .environmentObject(AuthViewModel.mock)
}
