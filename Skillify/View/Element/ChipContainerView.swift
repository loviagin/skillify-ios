//
//  ChipContainerView.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 01.02.2024.
//

import SwiftUI

struct ChipContainerView: View {
    @ObservedObject var viewModel: ChipsViewModel
    @ObservedObject var searchViewModel: SearchViewModel

    var body: some View {
        ScrollView {
            FlowLayout(data: $viewModel.chipArray) { $chip in
                ChipView(systemImage: chip.systemImage,
                         titleKey: chip.titleKey,
                         isSelected: $chip.isSelected,
                         viewModel: searchViewModel)
            }
            .padding()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [Color.blue.opacity(0.9), Color.red.opacity(0.9)],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
        )
        .cornerRadius(10)
    }
}
