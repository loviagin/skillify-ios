//
//  BlockedView.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 19.12.2023.
//

import SwiftUI

struct BlockedView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    
    var text: String? = nil
    
    var body: some View {
        Image("logo")
            .resizable()
            .scaledToFit()
            .frame(width: 100)
            .padding()
        
        if let text {
            Text("Sorry, you're blocked by reason:")
                .font(.title2)
            
            Text(text)
        } else {
            Text("Sorry, you're blocked by admin")
                .font(.title2)
        }
        
        Text("You can contact us via email: skillify@lovigin.com")
            .font(.title2)
            .multilineTextAlignment(.center)
            .onTapGesture {
                UIPasteboard.general.string = "skillify@lovigin.com"
            }
        Button {
            viewModel.signOut()
        } label: {
            Text("Log out")
                .frame(width: 100, height: 40)
                .foregroundColor(.white)
                .background(.blue)
                .cornerRadius(15)
        }
    }
}

#Preview {
    BlockedView()
        .environmentObject(AuthViewModel.mock)
}
