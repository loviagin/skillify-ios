//
//  ProView.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 19.12.2023.
//

import SwiftUI

struct ProView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: AuthViewModel
    
    @State private var showPro2 = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    Image("logoPro")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180)
                        .padding(.top, 60)
                    Text(UserHelper.isUserPro(viewModel.currentUser?.proDate) ? "You're already pro" : "Unlock Your Potential with Learnsy Pro")
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                        .font(.title2)
                        .padding(.vertical)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
                .background(LinearGradient(colors: [.brandBlue.opacity(0.4), .redApp.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing))
                
                HStack {
                    Image("icon1")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50)
                    Text("Unlimited Skill Exchange Sessions")
                        .fontWeight(.bold)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack {
                    Image("icon2")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50)
                    Text("Feedback and Skill Improvement")
                        .fontWeight(.bold)
                }
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack {
                    Image("icon3")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50)
                    Text("Access to Exclusive Workshops and Seminars")
                        .fontWeight(.bold)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack {
                    Image("icon5")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50)
                    Text("Emoji status next to the avatar")
                        .fontWeight(.bold)
                }
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack {
                    Image("icon4")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50)
                    Text("No Ads")
                        .fontWeight(.bold)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack {
                    Image("icon6")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100)
                    Text("Cancel Anytime Without Penalties")
                        .fontWeight(.bold)
                }
                
                Divider()
                
                if !UserHelper.isUserPro(viewModel.currentUser?.proDate) {
                    Button {
                        withAnimation {
                            showPro2 = true
                        }
                    } label: {
                        Text("Join Learnsy Pro Now!")
                            .padding()
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal)
                    .background(.redApp)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    
                    Button {
                        dismiss()
                    } label: {
                        Text("Maybe Later")
                            .foregroundStyle(.redApp)
                    }
                    .padding(5)
                } else {
                    VStack {
                        Text("Your subsription ends on")
                        Text("\(viewModel.currentUser?.proDate?.formatted(date: .complete, time: .omitted) ?? ""))")
                        
                        Text("To cancel your subscription, please go to the App Store -> Subscriptions")
                            .font(.caption2)
                            .multilineTextAlignment(.center)
                            .padding([.top, .leading, .trailing])
                    }
                }
                
                Spacer()
            }
            .ignoresSafeArea()
            .navigationDestination(isPresented: $showPro2) {
                Pro2View()
                    .toolbar(.hidden, for: .tabBar)
            }
        }
    }
    
    func formattedDate(from timeInterval: Double) -> String {
        let date = Date(timeIntervalSince1970: timeInterval)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMMM yyyy"
        return dateFormatter.string(from: date)
    }
}

#Preview {
    ProView()
        .environmentObject(AuthViewModel.mock)
}
