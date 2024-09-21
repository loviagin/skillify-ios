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
    @State var isSelected: Bool
    @ObservedObject var viewModel: SearchViewModel
    
    var body: some View {
        HStack(spacing: 4) {
            Image.init(systemName: systemImage).font(.body)
            Text(titleKey).foregroundColor(isSelected ? .white : .black).lineLimit(1)
        }
        .padding(.vertical, 5)
        .padding(.leading, 5)
        .padding(.trailing, 10)
        .foregroundColor(isSelected ? .white : .gray)
        .background(isSelected ? .blue : Color.white)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isSelected ? .brandBlue : .white, lineWidth: 0.5)
            
        ).onTapGesture {
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
