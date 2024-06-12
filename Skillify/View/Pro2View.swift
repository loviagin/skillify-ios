//
//  Pro2View.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 14.02.2024.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore
//import RevenueCat

struct Pro2View: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    @State private var price = "35.99"
    @State private var selectedOption: AuthViewModel.ProOption = .year
    @State private var showProAlert = false
    @State private var promocode = ""
    
    @State private var promocodes: [String] = []
    
    //    @State var currentOffering: Offering?
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Image("logoPro")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150)
                    .padding(.top, 50)
            }
            
            Spacer()
            
            Text("Choose Your Subscription Skillify Pro")
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .font(.title2)
                .fontWeight(.bold)
                .padding(.bottom)
            
            
            VStack {
                ZStack(alignment: .topTrailing) {
                    HStack {
                        Text("Monthly Subscription")
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                        Spacer()
                        Text("$4.99 per month")
                            .foregroundStyle(.white)
                            .font(.callout)
                    }
                    .padding()
                    .padding(.vertical)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .overlay {
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(.blue, lineWidth: 6)
                            .offset(x: 2, y: 2)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(.white, lineWidth: 4)
                    }
                    .onTapGesture {
                        price = "4.99"
                        selectedOption = .month
                    }
                    
                    if selectedOption == .month {
                        Image(systemName: "checkmark")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .padding(8)
                            .frame(width: 30, height: 30)
                            .background(.redApp)
                            .clipShape(Circle())
                            .foregroundStyle(.white)
                            .padding(.top, -15)
                    }
                }
                
                ZStack(alignment: .top) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Annual Subscription")
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                            (
                                Text("$59.99").strikethrough()
                                +
                                Text(" $35.99 per year")
                            )
                            .font(.caption)
                            .foregroundStyle(.white)
                            
                        }
                        Spacer()
                        Text("$2.99 per month")
                            .foregroundStyle(.white)
                            .font(.callout)
                    }
                    .padding()
                    .padding(.vertical)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .overlay {
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(.redApp, lineWidth: 6)
                            .offset(x: 2, y: 2)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(.blue, lineWidth: 4)
                    }
                    .padding(.vertical)
                    .onTapGesture {
                        price = "35.99"
                        selectedOption = .year
                    }
                    
                    Text("Save 40%")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(.redApp)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .padding(.top, 18)
                        .padding(.leading, 5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if selectedOption == .year {
                        Image(systemName: "checkmark")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .padding(8)
                            .frame(width: 30, height: 30)
                            .background(.redApp)
                            .clipShape(Circle())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .topTrailing)
                    }
                }
                
                Text("Cancel Anytime")
                    .foregroundStyle(.white)
                    .font(.callout)
                Button {
                    showProAlert = true
                    //                    Purchases.shared.purchase(package: offer.first!) { (transaction, customerInfo, error, userCancelled) in
                    //                        if customerInfo!.entitlements["pro"]?.isActive == true {
                    //                if let user = authViewModel.currentUser {
                    //                    let time = Date().timeIntervalSince1970 + 2592000000
                    //                    authViewModel.updateUsersIntFirebase(str: "pro", newStr: time, cUid: user.id)
                    //                    let db = Firestore.firestore()
                    //                    let data = ["cover:1", "emoji:sparkles", "status:star.fill"]
                    //                    db.collection("users").document(user.id)
                    //                        .updateData(["proData": FieldValue.arrayUnion(data)])
                    //                    authViewModel.currentUser!.proData = data
                    //                                do {
                    //                                    try db.collection("top-users").document(user.id).setData(from: userPro)
                    //                                } catch let error {
                    //                                    print("Error writing city to Firestore: \(error)")
                    //                                }
                    //                    authViewModel.currentUser!.pro = time
                    //                }
                    //                        }
                    //                    }
                    
                    //                presentationMode.wrappedValue.dismiss()
                } label: {
                    Text("Subscribe for $\(price)")
                        .frame(width: 300, height: 50)
                        .background(.white)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .cornerRadius(15)
                }
                .alert("Skillify Pro", isPresented: $showProAlert) {
                    TextField("Your promo", text: $promocode)
                    
                    Button {
                        if promocodes.contains(promocode) {
                            authViewModel.setPro(selectedOption)
                        }
                        dismiss()
                    } label: {
                        Text("Ok")
                    }
                    
                    Button(role: .cancel) {
                        dismiss()
                    } label: {
                        Text("Cancel")
                    }
                } message: {
                    Text("Enter your promo code")
                }

            }
            Spacer()
            //            if let offer = currentOffering?.availablePackages {
            
            //            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .onAppear {
            Firestore.firestore().collection("admin").document("system").getDocument { doc, error in
                if let error {
                    print(error)
                } else {
                    self.promocodes = doc?.get("promocodes") as? [String] ?? []
                }
            }
        }
        .background(
            LinearGradient(gradient: Gradient(colors: [.blue.opacity(0.4), .blue.opacity(0.4), .blue.opacity(0.4), .redApp.opacity(0.4)]), startPoint: .top, endPoint: .bottom)
        )
        .ignoresSafeArea()
        //        .onAppear {
        //            Purchases.shared.getOfferings { (offerings, error) in
        //                if let offerings {
        //                    currentOffering = offerings.current
        //                }
        //            }
        //        }
    }
}

#Preview {
    Pro2View()
        .environmentObject(AuthViewModel.mock)
}

struct ProExtraView: View {
    var text: String
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle")
                .foregroundColor(.white)
                .padding(.trailing, 5)
                .padding(.vertical, 10)
            Text(text)
                .foregroundColor(.white)
        }
    }
}
