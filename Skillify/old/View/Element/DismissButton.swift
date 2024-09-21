//
//  DismissButton.swift
//  Skillify
//
//  Created by Ilia Loviagin on 6/3/24.
//

import SwiftUI

struct DismissButton: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Button {
            dismiss()
        } label: {
            Text("Cancel")
                .frame(maxWidth: .infinity)
                .padding()
                .background(.lGray)
                .foregroundColor(.primary)
                .cornerRadius(15)
                .padding(.horizontal, 10)
        }
    }
}

#Preview {
    DismissButton()
}
