//
//  RegistrationView.swift
//  Skillify
//
//  Created by Ilia Loviagin on 10/5/25.
//

import SwiftUI

struct RegistrationView: View {
    var draft: AppUserDraft?
    
    var body: some View {
        Text("Hello, Registration! \(draft?.name ?? "no name")")
    }
}

#Preview {
    RegistrationView()
}
