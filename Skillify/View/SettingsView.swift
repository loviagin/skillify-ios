//
//  SettingsView.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 19.12.2023.
//

import SwiftUI

struct SettingsView: View {
    @State private var showDelete = false
    @State var counter = 0
    @EnvironmentObject var authViewModel: AuthViewModel
//    @State var proViewShow: Bool = false
//    @State private var showData = false
    
    var body: some View {
        List {
            Section(header: Text("Settings")) {
//                Text("Delete data")
//                    .foregroundColor(.red)
//                    .onTapGesture {
//                        showData = true
//                    }
//                    .sheet(isPresented: $showData) {
//                        SafariView(url:
//                                    URL(string: "https://skillify.loviagin.com/delete-account/")!)
//                    }
//                Text(UserHelper.isUserPro(authViewModel.currentUser!.pro) ? "You're already pro user" : "Developer option")
//                    .foregroundColor(.blue)
//                    .onTapGesture(perform: {
//                        if counter > 5 {
//                            proViewShow = true
//                            print("you're pro")
//                        } else {
//                            counter += 1
//                        }
//                    })
                Text("Delete account")
                    .foregroundColor(.red)
                    .onTapGesture {
                        showDelete = true
                    }
                    .sheet(isPresented: $showDelete) {
                        SafariView(url:
                                    URL(string: "https://skillify.space/delete-account/")!)
                    }
            }
            Section {
                Text(UserHelper.getAppVersion())
            }
        }
        .listStyle(PlainListStyle())
//        .sheet(isPresented: $proViewShow){
//            Pro2View()
//        }
    }
    
//    func sendNotification(title: String, body: String, token: String, uid: String) {
//        let url = URL(string: "https://us-central1-skillify-loviagin.cloudfunctions.net/sendNotification")!
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//
//        let json: [String: Any] = ["title": title, "body": body, "token": token, "uid": uid]
//        let jsonData = try? JSONSerialization.data(withJSONObject: json)
//
//        request.httpBody = jsonData
//
//        URLSession.shared.dataTask(with: request) { data, response, error in
//            if let error = error {
//                print("Error sending notification: \(error)")
//                return
//            }
//            if let response = response as? HTTPURLResponse, response.statusCode == 200 {
//                print("Notification sent successfully")
//            }
//        }.resume()
//    }
}

#Preview {
    SettingsView()
}
