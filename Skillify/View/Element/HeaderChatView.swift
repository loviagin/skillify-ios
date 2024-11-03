//
//  HeaderChatView.swift
//  Skillify
//
//  Created by Ilia Loviagin on 10/17/24.
//

import SwiftUI

struct HeaderChatView: View {
    @EnvironmentObject private var viewModel: ChatViewModel

    var body: some View {
        HStack {
            Text("Chats")
                .font(.title)
                .bold()
                .foregroundStyle(Color.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            
            Spacer()
            
            NavigationLink {
                MessagesView(userId: "Support")
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "questionmark.bubble")
                        .resizable()
                        .frame(width: 24, height: 24)
                    
                    if viewModel.countSupportUnread() > 0 { // Показываем бэдж только если есть непрочитанные сообщения
                        Text("\(viewModel.countSupportUnread())")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Color.red)
                            .clipShape(Circle())
                            .offset(x: 10, y: -10) // Смещение бэджа относительно иконки
                    }
                }
            }
            .padding()
        }
    }
}
