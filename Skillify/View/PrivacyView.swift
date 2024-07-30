//
//  PrivacyView.swift
//  Skillify
//
//  Created by Ilia Loviagin on 6/3/24.
//

import SwiftUI
import FirebaseFirestore

struct PrivacyView: View {
    @EnvironmentObject private var viewModel: AuthViewModel
    @State private var showProSheet = false
    
//    @State private var publicMessages = true
//    @State private var publicPhotos = true
//    @State private var publicVideos = true
//    
//    @State private var audioCalls = true
//    @State private var videoCalls = true
//    @State private var notPublicCalls = true
    
    @State private var notificationMessages = true
    @State private var notificationSubscriber = true
    @State private var notificationSystem = true
    
    @State private var selectedCountry: Countries = .other_countries
    @State private var showHidden = false
    
    private enum Countries: String {
        case russia = "russia"
        case other_countries = "other_countries"
    }
    
    var body: some View {
        NavigationStack {
            List {
//                Section {
//                    Toggle("All can send me messages", systemImage: "message.badge", isOn: $publicMessages)
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                    Toggle("All can send me photos", systemImage: "plus.message", isOn: $publicPhotos)
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                    Toggle("All can send me videos", systemImage: "plus.message", isOn: $publicVideos)
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                        .disabled(!UserHelper.isUserPro(viewModel.currentUser?.pro))
//                        .onTapGesture {
//                            if !UserHelper.isUserPro(viewModel.currentUser?.pro) {
//                                showProSheet = true
//                            }
//                        }
//                        .sheet(isPresented: $showProSheet) {
//                            ProView()
//                        }
//                } header: {
//                    Text("Messages")
//                }
                
//                Section {
//                    Toggle("Calls only for friends", systemImage: "phone.connection", isOn: $notPublicCalls)
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                        .disabled(!UserHelper.isUserPro(viewModel.currentUser?.pro))
//                        .onTapGesture {
//                            if !UserHelper.isUserPro(viewModel.currentUser?.pro) {
//                                showProSheet = true
//                            }
//                        }
//                        .sheet(isPresented: $showProSheet) {
//                            ProView()
//                        }
//                    Toggle("Audio calls", systemImage: "phone.badge.waveform.fill", isOn: $audioCalls)
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                    Toggle("Video calls", systemImage: "video.badge.waveform.fill", isOn: $videoCalls)
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                    
//                } header: {
//                    Text("Calls")
//                }
                
                Section {
                    Toggle("New messages", systemImage: "app.badge", isOn: $notificationMessages)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Toggle("New subscriber", systemImage: "app.badge", isOn: $notificationSubscriber)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Toggle("System notifications", systemImage: "app.badge.fill", isOn: $notificationSystem)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .disabled(!UserHelper.isUserPro(viewModel.currentUser?.pro))
                        .onTapGesture {
                            if !UserHelper.isUserPro(viewModel.currentUser?.pro) {
                                showProSheet = true
                            }
                        }
                        .sheet(isPresented: $showProSheet) {
                            ProView()
                        }
                    
                } header: {
                    Text("Notifications")
                }
                Section {
                    NavigationLink(destination: BlockedUsersView()) {
                        Text("Blocked users")
                    }
                    
                } header: {
                    Text("")
                }
                
                Section {
                    if showHidden {
                        Picker(selection: $selectedCountry, label: Text("Select payment region")) {
                            Text("Other countries").tag(Countries.other_countries)
                            Text("Russia").tag(Countries.russia)
                        }
                    }
                } header: {
                    Text("Other settings")
                }
            }
            .listStyle(PlainListStyle())
            .navigationTitle("Privacy & Security")
        }
        .onAppear {
            if let user = viewModel.currentUser, let data = user.privacyData {
                self.notificationSystem = !data.contains(where: { $0 == "blockSystemNotification" })
                self.notificationMessages = !data.contains(where: { $0 == "blockMessageNotification" })
                self.notificationSubscriber = !data.contains(where: { $0 == "blockSubscriptionNotification" })
            }
            
            Firestore.firestore().collection("admin").document("system")
                .getDocument { doc, error in
                    if error != nil {
                        print("error")
                    } else {
                        self.showHidden = doc?.get("allowRegions") as? Bool ?? false
                    }
                }
            
            if let country = UserDefaults.standard.string(forKey: "country"), country == "russia" {
                self.selectedCountry = .russia
            }
        }
        .onChange(of: selectedCountry) { _ in
            print(selectedCountry.rawValue)
            UserDefaults.standard.setValue(selectedCountry.rawValue, forKey: "country")
        }
        .onDisappear {
            var adding = []
            var deleting = []
            
            if notificationSystem {
                deleting.append("blockSystemNotification")
            } else {
                adding.append("blockSystemNotification")
            }
            
            if notificationMessages {
                deleting.append("blockMessageNotification")
            } else {
                adding.append("blockMessageNotification")
            }
            
            if notificationSubscriber {
                deleting.append("blockSubscriptionNotification")
            } else {
                adding.append("blockSubscriptionNotification")
            }
                        
            if let user = viewModel.currentUser {
                viewModel.currentUser!.privacyData = []
                viewModel.currentUser!.privacyData = adding as? [String]

                Firestore.firestore().collection("users").document(user.id)
                    .updateData([
                        "privacyData": FieldValue.arrayUnion(adding)
                    ])
                Firestore.firestore().collection("users").document(user.id)
                    .updateData([
                        "privacyData": FieldValue.arrayRemove(deleting)
                    ])
            }
        }
    }
}

#Preview {
    PrivacyView()
        .environmentObject(AuthViewModel.mock)
}
