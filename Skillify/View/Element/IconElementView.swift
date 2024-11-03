//
//  IconElementView.swift
//  Skillify
//
//  Created by Ilia Loviagin on 10/18/24.
//

import SwiftUI

struct IconElementView: View {
    let name: String
    
    var body: some View {
        ZStack {
            Circle()
                .fill(.blue.opacity(0.1))
                .frame(width: 55, height: 55)
            
            Image(systemName: name)
                .resizable()
                .scaledToFit()
                .frame(width: 30)
                .foregroundStyle(.gray)
        }
    }
}
