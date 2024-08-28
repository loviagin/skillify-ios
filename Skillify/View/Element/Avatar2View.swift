//
//  Avatar2View.swift
//  Skillify
//
//  Created by Ilia Loviagin on 5/24/24.
//

import SwiftUI
import Kingfisher

struct Avatar2View: View {
    var avatarUrl: String
    var size: CGFloat = 100
    var maxHeight: CGFloat = 130
    var maxWidth: CGFloat = .infinity
    
    var body: some View {
        VStack {
            if UserHelper.avatars.contains(avatarUrl.split(separator: ":").first.map(String.init) ?? "") {
                Image(avatarUrl.split(separator: ":").first.map(String.init) ?? "")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .foregroundColor(.gray)
                    .padding(.top, 10)
                    .frame(width: size, height: size)
                    .background(Color.fromRGBAString(avatarUrl.split(separator: ":").last.map(String.init) ?? "") ?? .blue.opacity(0.4))
                    .clipShape(Circle())
            } else if let url = URL(string: avatarUrl) {
                KFImage(url)
                    .resizable()
                    .placeholder {
                        Image("avatar1")
                            .resizable()
                            .scaledToFill()
                            .frame(width: size, height: size)
                            .clipShape(Circle())
                            .clipped()
                    }
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .clipped()
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .foregroundColor(.gray)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
//                    .padding(.bottom)
            }
        }
        .frame(maxWidth: maxWidth, maxHeight: maxHeight)
        .ignoresSafeArea(edges: .top)
//        .background(.lGray)
    }
}

#Preview {
    Avatar2View(avatarUrl: "https://url.com")
}
