//
//  HomeView.swift
//  Skillify
//
//  Created by Ilia Loviagin on 10/5/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var viewModel: AuthViewModel
    
    var body: some View {
        Text("Hello, Home!")
    }
}

#Preview {
    HomeView()
}
