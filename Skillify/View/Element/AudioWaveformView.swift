//
//  AudioWaveformView.swift
//  Skillify
//
//  Created by Ilia Loviagin on 10/17/24.
//

import SwiftUI

struct AudioWaveformView: View {
    var levels: [Float]
    var isCurrent = false

    var body: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .center, spacing: 2) {
                    ForEach(levels, id: \.self) { level in
                        BarView(value: CGFloat(level), maxHeight: geometry.size.height, isCurrent: isCurrent)
                    }
                }
                .frame(width: max(CGFloat(levels.count) * 5, geometry.size.width), height: geometry.size.height)
                .animation(.linear(duration: 0.1), value: levels)  // Анимация для плавного движения
            }
            .onAppear {
                print("levels \(levels)")
            }
        }
    }
}
