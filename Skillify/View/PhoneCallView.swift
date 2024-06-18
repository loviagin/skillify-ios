//
//  PhoneCallView.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 30.12.2023.
//

import SwiftUI
import FirebaseFirestore
import AVFoundation

struct PhoneCallView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var callManager: CallManager
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    @State private var user = User()
    
    var body: some View {
        ZStack(alignment: .center) {
            if callManager.video {
                VideoCallView(callManager: callManager)
                    .edgesIgnoringSafeArea(.all)
            } else {
                Image("call")
                    .resizable()
                    .scaledToFill()
                    .opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
            }
            
            VStack {
                if callManager.video {
//                    HStack {
//                        Avatar2View(avatarUrl: user.urlAvatar)
//                        VStack(alignment: .leading) {
//                            Text("\(user.first_name) \(user.last_name)")
//                                .font(.headline)
//                                .foregroundColor(.primary)
//                            Text("\(callManager.status ?? "")")
//                                .font(.caption)
//                                .foregroundColor(.primary)
//                        }
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                        Spacer()
//                    }
//                    .frame(maxWidth: .infinity)
//                    .padding()
                    Spacer()
                } else {
                    Spacer()
                    Avatar2View(avatarUrl: user.urlAvatar)
                    Text("\(user.first_name) \(user.last_name)")
                        .font(.title2)
                    Text("\(callManager.status ?? "")")
                        .font(.caption)
                        .foregroundColor(.primary)
                    Spacer()
                }
                
                HStack (spacing: 20) {
                    if callManager.video {
                        Button(action: {
                            callManager.agoraManager.agoraKit.switchCamera()
                        }) {
                            Image(systemName: "arrow.2.squarepath")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 35, height: 35)
                                .padding()
                                .background(.lGray)
                                .foregroundColor(.white)
                                .clipShape(Circle())
                        }
                    }
                    
                    Button(action: {
                        callManager.toggleMute()
                    }) {
                        Image(systemName: callManager.muted ? "mic.slash" : "mic")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 35, height: 35)
                            .padding()
                            .background(callManager.muted ? .lGray : .gray)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                    
                    if let _ = callManager.agoraManager.agoraKit {
                        Button {
                            callManager.endCall()
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            Image(systemName: "phone.down.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 35, height: 35)
                                .padding()
                                .background(.red)
                                .foregroundColor(.white)
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(.bottom, callManager.video ? 20 : 100)
            }
        }
        .onAppear {
            print("phone call onAppear")
            callManager.show = false

            if !callManager.incoming, let u = callManager.receiver {
                self.user = u
            } else if let u = callManager.handler {
                self.user = u
            }
            
            requestMicrophonePermission(completion: { _ in })
            if callManager.video {
                Task {
                    await _ = checkForPermissions()
                }
            }
        }
        .onDisappear {
            if callManager.callId != nil {
                callManager.show = true
            }
        }
        .onChange(of: callManager.status) { _ in
            if callManager.status == "Ended call" {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if granted {
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }
    }
    
    func checkForPermissions() async -> Bool {
        var hasPermissions = await self.avAuthorization(mediaType: .video)
        if !hasPermissions { return false }
        hasPermissions = await self.avAuthorization(mediaType: .audio)
        return hasPermissions
    }
    
    func avAuthorization(mediaType: AVMediaType) async -> Bool {
        let mediaAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: mediaType)
        switch mediaAuthorizationStatus {
        case .denied, .restricted: return false
        case .authorized: return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: mediaType) { granted in
                    continuation.resume(returning: granted)
                }
            }
        @unknown default: return false
        }
    }
}
