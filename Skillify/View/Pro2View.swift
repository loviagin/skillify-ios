//
//  Pro2View.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 14.02.2024.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore
import RevenueCat

struct Pro2View: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    @State private var price = "$34.99"
    @State private var selectedOption: Package?
    @State private var showProAlert = false
    @State private var promocode = ""
    
    @State private var promocodes: [String] = []
    
    @State var currentOffering: Offering?
    @State var showPrivacy: Bool = false
    @State var showTerms: Bool = false
    
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
            
            VStack {
                
                Spacer()
                
                Text("Choose Your Subscription")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Skillify Pro")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.bottom)
                
                if currentOffering != nil {
                    ForEach(currentOffering!.availablePackages) { pkg in
                        if pkg.storeProduct.localizedTitle == "Annual subscription" {
                            ZStack {
                                Image((selectedOption?.storeProduct.localizedTitle == "Annual subscription" || selectedOption == nil) ? "price-2" : "rect-3")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: .infinity)
                                
                                VStack {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text("\(pkg.storeProduct.localizedTitle)")
                                                .fontWeight(.bold)
                                                .foregroundStyle(.white)
                                            
                                            Text("\(pkg.storeProduct.localizedPricePerYear ?? "") per year")
                                                .font(.callout)
                                                .fontWeight(.bold)
                                                .foregroundStyle(.white)
                                        }
                                        
                                        Spacer()
                                        
                                        Text("\(pkg.storeProduct.localizedPricePerMonth ?? "")")
                                            .foregroundStyle(.white)
                                            .font(.caption)
                                            .fontWeight(.bold)

                                        Text("per month")
                                            .foregroundStyle(.white)
                                            .fontWeight(.bold)
                                            .font(.caption)
                                        
                                    }
                                    .padding(20)
                                }
                            }
                            .onTapGesture {
                                withAnimation {
                                    price = pkg.storeProduct.localizedPriceString
                                    selectedOption = pkg
                                }
                            }
                        } else {
                            ZStack {
                                Image((selectedOption?.storeProduct.localizedTitle == "Annual subscription" || selectedOption == nil) ? "price-1" : "rect-5")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: .infinity)
                                
                                VStack {
                                    HStack {
                                        Text("\(pkg.storeProduct.localizedTitle)")
                                            .fontWeight(.bold)
                                            .foregroundStyle(.white)
                                        
                                        Spacer()
                                        
                                        Text("\(pkg.storeProduct.localizedPricePerMonth ?? "")")
                                            .foregroundStyle(.white)
                                            .font(.caption)
                                            .fontWeight(.bold)
                                        
                                        Text("per month")
                                            .foregroundStyle(.white)
                                            .font(.caption)
                                            .fontWeight(.bold)
                                    }
                                    .padding(20)
                                }
                            }
                            .padding(.bottom)
                            .onTapGesture {
                                withAnimation {
                                    price = pkg.storeProduct.localizedPriceString
                                    selectedOption = pkg
                                }
                            }
                        }
                    }
                }
                //                ZStack(alignment: .topTrailing) {
//                    HStack {
//                        Text("Monthly Subscription")
//                            .fontWeight(.bold)
//                            .foregroundStyle(.white)
//                        Spacer()
//                        Text("$4.99 per month")
//                            .foregroundStyle(.white)
//                            .font(.callout)
//                    }
//                    .padding()
//                    .padding(.vertical)
//                    .frame(maxWidth: .infinity)
//                    .clipShape(RoundedRectangle(cornerRadius: 15))
//                    .overlay {
//                        RoundedRectangle(cornerRadius: 15)
//                            .stroke(.blue, lineWidth: 6)
//                            .offset(x: 2, y: 2)
//                    }
//                    .overlay {
//                        RoundedRectangle(cornerRadius: 15)
//                            .stroke(.white, lineWidth: 4)
//                    }
//                    .onTapGesture {
//                        price = "4.99"
//                        selectedOption = .month
//                    }
//                    
//                    if selectedOption == .month {
//                        Image(systemName: "checkmark")
//                            .resizable()
//                            .aspectRatio(contentMode: .fill)
//                            .padding(8)
//                            .frame(width: 30, height: 30)
//                            .background(.redApp)
//                            .clipShape(Circle())
//                            .foregroundStyle(.white)
//                            .padding(.top, -15)
//                    }
//                }
//                
//                ZStack(alignment: .top) {
//                    HStack {
//                        VStack(alignment: .leading) {
//                            Text("Annual Subscription")
//                                .fontWeight(.bold)
//                                .foregroundStyle(.white)
//                            (
//                                Text("$59.99").strikethrough()
//                                +
//                                Text(" $34.99 per year")
//                            )
//                            .font(.caption)
//                            .foregroundStyle(.white)
//                            
//                        }
//                        Spacer()
//                        Text("$2.99 per month")
//                            .foregroundStyle(.white)
//                            .font(.callout)
//                    }
//                    .padding()
//                    .padding(.vertical)
//                    .frame(maxWidth: .infinity)
//                    .clipShape(RoundedRectangle(cornerRadius: 15))
//                    .overlay {
//                        RoundedRectangle(cornerRadius: 15)
//                            .stroke(.redApp, lineWidth: 6)
//                            .offset(x: 2, y: 2)
//                    }
//                    .overlay {
//                        RoundedRectangle(cornerRadius: 15)
//                            .stroke(.blue, lineWidth: 4)
//                    }
//                    .padding(.vertical)
//                    .onTapGesture {
//                        price = "34.99"
//                        selectedOption = .year
//                    }
//                    
//                    Text("Save 40%")
//                        .font(.caption)
//                        .padding(.horizontal, 8)
//                        .padding(.vertical, 5)
//                        .background(.redApp)
//                        .foregroundColor(.white)
//                        .clipShape(RoundedRectangle(cornerRadius: 15))
//                        .padding(.top, 18)
//                        .padding(.leading, 5)
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                    
//                    if selectedOption == .year {
//                        Image(systemName: "checkmark")
//                            .resizable()
//                            .aspectRatio(contentMode: .fill)
//                            .padding(8)
//                            .frame(width: 30, height: 30)
//                            .background(.redApp)
//                            .clipShape(Circle())
//                            .foregroundStyle(.white)
//                            .frame(maxWidth: .infinity, alignment: .topTrailing)
//                    }
//                }
            
                Spacer()

                Text("Cancel Anytime")
                    .foregroundStyle(.white)
                    .font(.caption)
                Button {
                    if let c = UserDefaults.standard.string(forKey: "country") , c == "russia" {
                        showProAlert = true
                    } else {
                        if currentOffering != nil {
                            Purchases.shared.purchase(package: (selectedOption ?? currentOffering?.availablePackages.last!)!) { trans, custInfo, error, uCanceled  in
                                if custInfo?.entitlements.all["pro"]?.isActive == true {
//                                    authViewModel.setPro(selectedOption)
                                    dismiss()
                                }
                            }
                            print("done")
                        } else {
                            showProAlert = true
                        }
                    }
                } label: {
                    Text("Subscribe for \(price)")
                        .frame(width: 300, height: 50)
                        .background(Image("button-2").resizable())
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .cornerRadius(15)
                }
                .alert("Skillify Pro", isPresented: $showProAlert) {
                    TextField("Your promo", text: $promocode)
                    
                    Button {
                        if promocodes.contains(where: { $0.split(separator: ":").first ?? "" == promocode }) {
                            if promocodes.contains(where: { $0.split(separator: ":").last == "12" }) {
                                authViewModel.setPro(.year)
                            } else {
                                authViewModel.setPro(.month)
                            }
                        }
                        dismiss()
                    } label: {
                        Text("Ok")
                    }
                    
                    Button(role: .cancel) {
//                        dismiss()
                    } label: {
                        Text("Cancel")
                    }
                } message: {
                    Text("Enter your promo code")
                }
                
                HStack {
                    Text("Privacy policy ")
                        .multilineTextAlignment(.center)
                        .font(.caption2)
                        .onTapGesture {
                            showPrivacy = true
                        }
                    Spacer()

                    Text("Terms of Us")
                        .multilineTextAlignment(.center)
                        .font(.caption2)
                        .onTapGesture {
                            showTerms = true
                        }
                    
                }
                .padding(.horizontal, 50)
                .padding(.vertical, 8)
                .sheet(isPresented: $showPrivacy, content: {
                    SafariView(url: URL(string: "https://skillify.space/privacy-policy/")!)
                        .ignoresSafeArea()
                })
                .sheet(isPresented: $showTerms, content: {
                    SafariView(url: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                        .ignoresSafeArea()
                })
                
                Text("Your monthly or yearly subscription will automatically renew under the same conditions unless you cancel it at least 24 hours before the end of the current period. You can cancel your subscription at any time without any additional charges through the App Store, and it will terminate at the end of the current period.")
                    .multilineTextAlignment(.center)
                    .font(.caption2)
                    .padding(.horizontal)

            }
            //            if let offer = currentOffering?.availablePackages {
            
            //            }
            Spacer()
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .onAppear {
            Firestore.firestore().collection("admin").document("system").getDocument { doc, error in
                if let error {
                    print(error)
                } else {
                    self.promocodes = doc?.get("promocodes") as? [String] ?? []
                }
            }
            
            Purchases.shared.getOfferings { offerings, error in
                if let offer = offerings?.current, error == nil {
                    currentOffering = offer
                    self.price = offer.availablePackages.last?.localizedPriceString ?? "$34.99"
                }
            }
        }
        .background(Image("rectangle"))
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
