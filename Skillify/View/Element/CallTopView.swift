//
//  CallTopView.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 18.03.2024.
//

import SwiftUI

struct CallTopView: View {
    @EnvironmentObject var callManager: CallManager
    
    var body: some View {
        NavigationLink(destination: PhoneCallView()) {
            HStack {
                Text("Calling")
                    .foregroundStyle(.white)
                    .padding()
                
                Spacer()
                
                Text("\(callManager.status ?? "")")
                    .foregroundStyle(.white)
                    .padding()
            }
            .background(.blue)
            .padding(0)
        }
        .frame(maxHeight: 30)
    }
}

#Preview {
    CallTopView()
}
