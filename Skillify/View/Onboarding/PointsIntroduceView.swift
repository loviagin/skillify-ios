//
//  PointsIntroduceView.swift
//  Skillify
//
//  Created by Ilia Loviagin on 11/17/24.
//

import SwiftUI

struct PointsIntroduceView: View {
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "bolt.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 60)
                .foregroundStyle(
                    LinearGradient(colors: [.blue.opacity(0.8), .red], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            
            Text("Collect Talents and Earn Rewards!")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            Text("Earning Talents is simple:")
                .multilineTextAlignment(.center)
            
            Text("• Schedule meetings directly in chats\n• Complete courses\n• Log into the app every day")

            Text("Gather 500 Talents and enjoy a free Pro subscription for an entire week. Come back for more rewards as many times as you want!")
                .multilineTextAlignment(.center)
//                .font(.subheadline)
//                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    PointsIntroduceView()
}
