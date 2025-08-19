//
//  BarView.swift
//  Skillify
//
//  Created by Ilia Loviagin on 10/17/24.
//

import SwiftUI

struct BarView: View {
    var value: CGFloat
    var maxHeight: CGFloat
    var isCurrent: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(isCurrent ? Color.white : Color.blue)
            .frame(width: 3, height: maxHeight * value)
    }
}
