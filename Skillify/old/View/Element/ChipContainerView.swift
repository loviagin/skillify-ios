//
//  ChipContainerView.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 01.02.2024.
//

import SwiftUI

struct ChipContainerView: View {
    @ObservedObject var viewModel = ChipsViewModel()
    @ObservedObject var searchViewModel: SearchViewModel
    
    var body: some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        return GeometryReader { geo in
            ZStack(alignment: .topLeading, content: {
                ForEach(viewModel.chipArray) { data in
                    ChipView(systemImage: data.systemImage,
                             titleKey: data.titleKey,
                             isSelected: data.isSelected, viewModel: searchViewModel)
                        .padding(.all, 5)
                        .alignmentGuide(.leading) { dimension in
                            if (abs(width - dimension.width) > geo.size.width) {
                                width = 0
                                height -= dimension.height
                            }
                            let result = width
                            if data.id == viewModel.chipArray.last!.id {
                                width = 0
                            } else {
                                width -= dimension.width
                            }
                            return result
                        }
                        .alignmentGuide(.top) { dimension in
                            let result = height
                            if data.id == viewModel.chipArray.last!.id {
                                height = 0
                            }
                            return result
                        }
                }
            })
        }
    }
}

struct ChipContainerView_Previews: PreviewProvider {
    static var previews: some View {
        ChipContainerView(searchViewModel: SearchViewModel(chipArray: []))
    }
}
