//
//  PointScoreView.swift
//  Skillify
//
//  Created by Ilia Loviagin on 11/17/24.
//

import SwiftUI

struct PointScoreView: View {
    @State var points: Int = 10
    
    var body: some View {
        HStack {
            Image(systemName: "bolt.fill")
                .foregroundStyle(.white)
            
            Text("\(points)")
                .foregroundStyle(.white)
                .bold()
        }
        .padding()
        .background(LinearGradient(colors: [.blue.opacity(0.8), .red.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(RoundedRectangle(cornerRadius: 55))
    }
}

#Preview {
    PointScoreView()
}
