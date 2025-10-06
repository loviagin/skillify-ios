//
//  AppButton.swift
//  Skillify
//
//  Created by Ilia Loviagin on 9/23/25.
//

import SwiftUI

struct AppButton: View {
    @State var text: String
    @State var image: String?
    @State var background: Color = .newBlue
    @State var foreground: Color = .white
    @State var isBold: Bool = true
    @Binding var isLoading: Bool
    @State var action: () -> Void = { }
    
    var body: some View {
        Button {
            action()
        } label: {
            HStack {
                if isLoading {
                    ProgressView()
                } else {
                    if let image {
                        Image(systemName: image)
                    }
                }
                
                Text(text)
            }
            .disabled(isLoading)
            .bold(isBold)
            .frame(maxWidth: .infinity)
            .padding()
            .background(background)
            .foregroundStyle(foreground)
            .clipShape(RoundedRectangle(cornerRadius: 15))
        }
        .buttonStyle(.plain)
    }
}
