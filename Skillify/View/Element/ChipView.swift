//
//  ChipView.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 19.12.2023.
//

import SwiftUI

struct ChipView: View {
    let systemImage: String
    let titleKey: String
    @Binding var isSelected: Bool
    @ObservedObject var viewModel: SearchViewModel

    var body: some View {
        HStack(spacing: 4) {
            if !systemImage.isEmpty {
                Image(systemName: systemImage)
            }
            Text(titleKey)
                .font(.callout)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .foregroundColor(.white)
        .background(isSelected ? Color.blue : Color.white.opacity(0.2))
        .cornerRadius(16)
        .onTapGesture {
            isSelected.toggle()
            DispatchQueue.main.async {
                let index = self.viewModel.chipArray.firstIndex(where: { $0.titleKey == titleKey })
                if let i = index {
                    self.viewModel.toggleChipSelection(at: i)
                }
            }
        }
    }
}
