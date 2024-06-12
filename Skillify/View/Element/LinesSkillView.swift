//
//  LinesSkillView.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 20.12.2023.
//

import SwiftUI

struct LinesSkillView: View {
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "rectangle.fill")
                .resizable()
                .frame(width: 20, height: 4)
                .foregroundColor(.blue)
            
            Image(systemName: "rectangle.fill")
                .resizable()
                .frame(width: 20, height: 4)
                .foregroundColor(.blue)

            Image(systemName: "rectangle.fill")
                .resizable()
                .frame(width: 20, height: 4)
                .foregroundColor(.blue)
        }
    }
}

#Preview {
    LinesSkillView()
}
