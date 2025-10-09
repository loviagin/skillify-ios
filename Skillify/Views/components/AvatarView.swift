//
//  AvatarView.swift
//  Skillify
//
//  Created by Ilia Loviagin on 10/6/25.
//

import SwiftUI

struct AvatarView: View {
    @Binding var avatarImage: UIImage?
    @Binding var avatarUrl: String?
    
    @State var size: CGFloat = 120
    
    var body: some View {
        if let avatarImage {
            Image(uiImage: avatarImage)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else if let avatarUrl {
            if Avatars.avatars.contains(avatarUrl) {
                Image(avatarUrl)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .background(
                        Circle()
                            .fill(Color.newBlue.opacity(0.5))
                            .frame(width: size, height: size)
                    )
            } else if let url = URL(string: avatarUrl) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: size, height: size)
                            .clipShape(Circle())
                            .background(
                                Circle()
                                    .fill(Color.newBlue.opacity(0.5))
                                    .frame(width: size, height: size)
                            )
                    } else if phase.error != nil {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: size, height: size)
                            .overlay {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 30))
                                    .foregroundStyle(.red)
                            }
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: size, height: size)
                            .overlay {
                                ProgressView()
                            }
                    }
                }
            }
        } else {
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: size, height: size)
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.gray)
                }
        }
    }
}
