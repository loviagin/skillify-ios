//
//  FlowLayout.swift
//  Skillify
//
//  Created by Ilia Loviagin on 10/17/24.
//

import SwiftUI

struct FlowLayout<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable {
    let data: Data
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: (Data.Element) -> Content

    init(data: Data,
         spacing: CGFloat = 8,
         alignment: HorizontalAlignment = .leading,
         @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.spacing = spacing
        self.alignment = alignment
        self.content = content
    }

    var body: some View {
        let rows = self.computeRows()

        return VStack(alignment: alignment, spacing: spacing) {
            ForEach(rows.indices, id: \.self) { rowIndex in
                HStack(spacing: spacing) {
                    ForEach(rows[rowIndex]) { item in
                        content(item)
                    }
                }
            }
        }
    }

    private func computeRows() -> [[Data.Element]] {
        var rows: [[Data.Element]] = [[]]
        var currentRow = 0
        var remainingWidth = UIScreen.main.bounds.width - 40 // Adjust for padding

        for item in data {
            let itemWidth = itemWidth(item: item) + spacing

            if remainingWidth - itemWidth >= 0 {
                rows[currentRow].append(item)
            } else {
                // Start new row
                rows.append([item])
                currentRow += 1
                remainingWidth = UIScreen.main.bounds.width - 40 - itemWidth
            }
            remainingWidth -= itemWidth
        }

        return rows
    }

    private func itemWidth(item: Data.Element) -> CGFloat {
        let hostingController = UIHostingController(rootView: content(item))
        hostingController.view.layoutIfNeeded()
        let size = hostingController.sizeThatFits(in: CGSize(width: CGFloat.infinity, height: CGFloat.infinity))
        return size.width
    }
}
