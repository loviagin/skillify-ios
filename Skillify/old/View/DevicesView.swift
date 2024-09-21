//
//  DevicesView.swift
//  Skillify
//
//  Created by Ilia Loviagin on 6/3/24.
//

import SwiftUI
import FirebaseFirestore

struct DevicesView: View {
    @EnvironmentObject private var viewModel: AuthViewModel
    
    var body: some View {
        VStack {
            if let user = viewModel.currentUser, !user.devices.isEmpty {
                List {
                    ForEach(user.devices, id: \.self) { it in
                        HStack {
                            if let token = UserDefaults.standard.string(forKey: "voipToken"), token == it {
                                Label("This device", systemImage: "iphone.gen2")
                            } else {
                                Text("Device \(it)")
                                    .lineLimit(1)
                                Spacer()
                                Image(systemName: "iphone.gen3.circle")
                                    .symbolRenderingMode(.multicolor)
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            if let token = UserDefaults.standard.string(forKey: "voipToken"), token != it {
                                Button(role: .destructive) {
                                    Firestore.firestore().collection("users").document(user.id).updateData(["devices": FieldValue.arrayRemove([it])])
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            } else {
                Text("No devices")
            }
        }
        .navigationTitle("My devices")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let token = UserDefaults.standard.string(forKey: "voipToken"), let u = viewModel.currentUser, !u.devices.isEmpty {
                if let d = u.devices.first(where: { $0 == token }) {
                    viewModel.currentUser!.devices.removeAll(where: { $0 == d })
                    viewModel.currentUser!.devices.insert(d, at: 0)
                }
            }
        }
    }
}

#Preview {
    DevicesView()
        .environmentObject(AuthViewModel.mock)
}
