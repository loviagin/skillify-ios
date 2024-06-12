//
//  CustomizeProfileView.swift
//  Skillify
//
//  Created by Ilia Loviagin on 6/2/24.
//

import SwiftUI
import FirebaseFirestore

struct CustomizeProfileView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var viewModel: AuthViewModel
    
    @State var cover: String = "cover:1"
    @State private var isCoverChooserShow = false
    @State var emoji = "emoji:sparkles"
    @State private var isEmojiPickerShow = false
    @State var status = "status:moon.stars"
    @State private var isStatusPickerShow = false
//    @State private var color: Color = .brandBlue
    
    @State private var name = ""
    
    var body: some View {
        VStack(alignment: .leading) {
            // MARK: - First section - COVER
            Text("Profile's cover")
                .frame(maxWidth: .infinity, alignment: .leading)
            ZStack {
                CoverView(name: cover)
                    .sheet(isPresented: $isCoverChooserShow) {
                        CoverChooserView(cover: $cover)
                            .presentationDetents([.medium])
                    }
                
                EmojiCoverView(emoji: $emoji)
            }
            Avatar2View(avatarUrl: viewModel.currentUser!.urlAvatar, size: 70, maxHeight: 0)
            
            // MARK: - First (2) section - STATUS
            HStack {
                Text("Choose background image")
                Spacer()
                Image(systemName: "paintbrush.fill")
                    .frame(width: 25, height: 25)
                    .foregroundColor(.white)
                    .padding(10)
                    .background(.gray)
                    .cornerRadius(15)
                    .padding(.horizontal)
                    .onTapGesture {
                        isCoverChooserShow = true
                    }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.lGray)
            .cornerRadius(15)
            .padding(.top, 50)
            
            // MARK: - Second section - STATUS
            HStack {
                Text("Emoji for cover picture")
                Spacer()
                Image(systemName: name)
                    .frame(width: 25, height: 25)
                    .foregroundColor(.white)
                    .padding(10)
                    .background(.gray)
                    .cornerRadius(15)
                    .padding(.horizontal)
                    .onTapGesture {
                        isEmojiPickerShow = true
                    }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.lGray)
            .cornerRadius(15)
            .padding(.top, 10)
            .sheet(isPresented: $isEmojiPickerShow) {
                EmojiPickerView(emoji: $emoji)
                    .presentationDetents([.height(300)])
            }
            
            //MARK: - Status EMOJI
            VStack {
                HStack(alignment: .center) {
                    Text("\(viewModel.currentUser?.first_name ?? "") \(viewModel.currentUser?.last_name ?? "")")
                        .font(.title3)
                    Image(systemName: String(status.split(separator: ":").last ?? Substring(status)))
                        .foregroundColor(.brandBlue)
                }
                
                HStack {
                    Text("Icon near your name")
                    Spacer()
                    Image(systemName: String(status.split(separator: ":").last ?? Substring(status)))
                        .frame(width: 25, height: 25)
                        .foregroundColor(.white)
                        .padding(10)
                        .background(.gray)
                        .cornerRadius(15)
                        .padding(.horizontal)
                        .onTapGesture {
                            isStatusPickerShow = true
                        }
                }
                
//                ColorPicker("Profile color", selection: $color)
//                    .padding(.top, 10)
//                    .padding(.trailing, 20)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.lGray)
            .cornerRadius(15)
            .padding(.vertical)
            .sheet(isPresented: $isStatusPickerShow) {
                StatusPickerView(status: $status)
                    .presentationDetents([.height(300)])
            }

            Spacer()
        }
        .onAppear {
            if let proData = viewModel.currentUser?.proData, proData.contains(where: { $0.hasPrefix("cover:") }) {
                self.cover = proData.first(where: { $0.hasPrefix("cover:") }) ?? "cover:1"
            }
            
            if let proData = viewModel.currentUser?.proData, proData.contains(where: { $0.hasPrefix("emoji:") }) {
                self.emoji = proData.first(where: { $0.hasPrefix("emoji:") }) ?? "emoji:sparkles"
            }
            
            if let proData = viewModel.currentUser?.proData, proData.contains(where: { $0.hasPrefix("status:") }) {
                self.status = proData.first(where: { $0.hasPrefix("status:") }) ?? "status:star.fill"
            }
            
//            if let tags = viewModel.currentUser?.tags, tags.contains(where: { $0.hasPrefix("color:") }) {
//                let getted = tags.first(where: { $0.hasPrefix("color:") }) ?? "color:blue"
//                self.color = Color(String(getted.split(separator: ":").last ?? Substring(getted)))
//            }
            
            self.name = String(emoji.split(separator: ":").last ?? Substring(emoji))
        }
        .onDisappear {
            let oldCover = viewModel.currentUser?.proData?.first(where: { $0.hasPrefix("cover:") })
            let oldEmoji = viewModel.currentUser?.proData?.first(where: { $0.hasPrefix("emoji:") })
            let oldStatus = viewModel.currentUser?.proData?.first(where: { $0.hasPrefix("status:") })
            
            viewModel.currentUser?.proData?.removeAll(where: { $0.hasPrefix("cover:") })
            viewModel.currentUser?.proData?.removeAll(where: { $0.hasPrefix("emoji:") })
            viewModel.currentUser?.proData?.removeAll(where: { $0.hasPrefix("status:") })
            viewModel.currentUser?.proData?.append(cover)
            viewModel.currentUser?.proData?.append(emoji)
            viewModel.currentUser?.proData?.append(status)
            
            Firestore.firestore().collection("users").document(viewModel.currentUser?.id ?? "user")
                .updateData([
                    "proData": FieldValue.arrayRemove([oldCover ?? "", oldEmoji ?? "", oldStatus ?? ""])
                ])
            
            Firestore.firestore().collection("users").document(viewModel.currentUser?.id ?? "user")
                .updateData([
                    "proData": FieldValue.arrayUnion([cover, emoji, status])
                ])
        }
        .onChange(of: emoji) { _ in
            self.name = String(emoji.split(separator: ":").last ?? Substring(emoji))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .navigationTitle("Customization")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CoverView: View {
    var name: String
    
    var body: some View {
        Rectangle()
            .fill(LinearGradient(
                gradient: Gradient(colors: [UserHelper.getColor1(name), UserHelper.getColor2(name)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .cornerRadius(15)
    }
}

struct EmojiPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var emoji: String
    
    var body: some View {
        Text("Choose emoji for your profile")
            .font(.title3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
        Grid {
            LazyVGrid(columns:[
                GridItem(.adaptive(minimum: 70, maximum: 150)),
                GridItem(.adaptive(minimum: 70, maximum: 150)),
                GridItem(.adaptive(minimum: 70, maximum: 150)),
                GridItem(.adaptive(minimum: 70, maximum: 150)),
                GridItem(.adaptive(minimum: 70, maximum: 150))
            ], content: {
                ForEach(UserHelper.emojies, id: \.self) { it in
                    Image(systemName: it)
                        .foregroundColor(.brandBlue)
//                        .symbolRenderingMode(.multicolor)
                        .padding()
                        .frame(width: 70, height: 70)
                        .background(.lGray)
                        .cornerRadius(15)
                        .onTapGesture {
                            emoji = "emoji:\(it)"
                            dismiss()
                        }
                }
            })
        }
        .padding(.horizontal)
        
        DismissButton()
            .padding([.horizontal, .top], 5)
    }
}

struct StatusPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var status: String
    
    var body: some View {
        Text("Set emoji-status for your profile")
            .font(.title3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
        Grid {
            LazyVGrid(columns:[
                GridItem(.adaptive(minimum: 70, maximum: 150)),
                GridItem(.adaptive(minimum: 70, maximum: 150)),
                GridItem(.adaptive(minimum: 70, maximum: 150)),
                GridItem(.adaptive(minimum: 70, maximum: 150)),
                GridItem(.adaptive(minimum: 70, maximum: 150))
            ], content: {
                ForEach(UserHelper.statuses, id: \.self) { it in
                    Image(systemName: it)
                        .foregroundColor(.brandBlue)
                        .symbolRenderingMode(.multicolor)
                        .padding()
                        .frame(width: 70, height: 70)
                        .background(.lGray)
                        .cornerRadius(15)
                        .onTapGesture {
                            status = "status:\(it)"
                            dismiss()
                        }
                }
            })
        }
        .padding(.horizontal)
        
        DismissButton()
            .padding([.horizontal, .top], 5)
    }
}

#Preview {
    CustomizeProfileView()
        .environmentObject(AuthViewModel.mock)
}
