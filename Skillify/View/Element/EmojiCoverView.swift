//
//  EmojiCoverView.swift
//  Skillify
//
//  Created by Ilia Loviagin on 6/3/24.
//

import SwiftUI

struct EmojiCoverView: View {
    @Binding var emoji: String
    @State var showLast1: Bool = true
    
    var body: some View {
        let name = String(emoji.split(separator: ":").last ?? Substring(emoji))
        
        ZStack {
            Image(systemName: name)
                .foregroundColor(.white.opacity(0.8))
                .padding()
                .frame(maxWidth: .infinity, maxHeight: 100, alignment: .topLeading)
            Image(systemName: name)
                .foregroundColor(.white.opacity(0.8))
                .padding()
                .frame(maxWidth: .infinity, maxHeight: 100, alignment: .top)
            Image(systemName: name)
                .foregroundColor(.white.opacity(0.8))
                .padding(.leading, 90)
                .frame(maxWidth: .infinity, maxHeight: 100, alignment: .leading)
            Image(systemName: name)
                .foregroundColor(.white.opacity(0.8))
                .padding(.leading, 90)
                .padding(.bottom)
                .frame(maxWidth: .infinity, maxHeight: 100, alignment: .bottom)
            Image(systemName: name)
                .foregroundColor(.white.opacity(0.8))
                .padding(.trailing, 60)
                .padding(.bottom)
                .frame(maxWidth: .infinity, maxHeight: 100, alignment: .trailing)
            Image(systemName: name)
                .foregroundColor(.white.opacity(0.8))
                .padding(.leading, 30)
                .padding(.bottom)
                .frame(maxWidth: .infinity, maxHeight: 100, alignment: .bottomLeading)
            Image(systemName: name)
                .foregroundColor(.white.opacity(0.8))
                .padding(.leading, 110)
                .padding(.top, 5)
                .frame(maxWidth: .infinity, maxHeight: 100, alignment: .top)
            Image(systemName: name)
                .foregroundColor(.white.opacity(0.8))
                .padding(.trailing, 30)
                .padding(.bottom, 10)
                .frame(maxWidth: .infinity, maxHeight: 100, alignment: .bottom)
            if showLast1 {
                Image(systemName: name)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.trailing, 20)
                    .padding(.bottom, 5)
                    .frame(maxWidth: .infinity, maxHeight: 100, alignment: .bottomTrailing)
                
                Image(systemName: name)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.trailing, 20)
                    .padding(.top, 10)
                    .frame(maxWidth: .infinity, maxHeight: 100, alignment: .topTrailing)
            }
        }
//        .background(.blue)
    }
}

#Preview {
    EmojiCoverView(emoji: .constant("sparkles"))
}
