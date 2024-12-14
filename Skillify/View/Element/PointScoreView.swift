//
//  PointScoreView.swift
//  Skillify
//
//  Created by Ilia Loviagin on 11/17/24.
//

import SwiftUI

struct PointScoreView: View {
    @EnvironmentObject private var viewModel: PointsViewModel
    @State var points: Int = 0
    
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "bolt.fill")
                .foregroundStyle(.white)
            
            if points > 0 {
                Text("\(points)")
                    .foregroundStyle(.white)
                    .bold()
            }
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 10)
        .background(LinearGradient(colors: [.blue.opacity(0.8), .red.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(RoundedRectangle(cornerRadius: 55))
        .onChange(of: viewModel.gamePoints) { _, newValue in
            withAnimation {
                self.points = viewModel.getSummaryPoints()
            }
        }
    }
}

#Preview {
    PointScoreView()
}
