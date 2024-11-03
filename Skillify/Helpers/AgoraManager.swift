//
//  AgoraManager.swift
//  Skillify
//
//  Created by Ilia Loviagin on 5/22/24.
//

import AgoraRtcKit
import AVFoundation
import CallKit

class AgoraManager: NSObject, ObservableObject {
    var agoraKit: AgoraRtcEngineKit!
    var provider: CXProvider?
    var callId: UUID?
    var users: [UInt] = []
    weak var callManager: CallManager?
    
    private var delegates = NSHashTable<AnyObject>.weakObjects()
    
    init(appId: String, callManager: CallManager) {
        super.init()
        agoraKit = AgoraRtcEngineKit.sharedEngine(withAppId: appId, delegate: self)
        self.callManager = callManager
    }
    
    func addDelegate(_ delegate: AgoraRtcEngineDelegate) {
        delegates.add(delegate)
    }
    
    func removeDelegate(_ delegate: AgoraRtcEngineDelegate) {
        delegates.remove(delegate)
    }
    
    func joinChannel(channel: String, token: String?, videoCall: Bool, provider: CXProvider, callId: UUID, completion: @escaping (UInt) -> Void) {
        self.provider = provider
        self.callId = callId
        if let token {
            agoraKit.joinChannel(byToken: token, channelId: channel, info: nil, uid: 0) { (channel, uid, elapsed) in
                self.setup(videoCall: videoCall)
                print("Joined channel: \(channel) with uid: \(uid)")
                self.users.append(uid)
                completion(uid)
            }
        } else {
            agoraKit.joinChannel(byToken: nil, channelId: channel, info: nil, uid: 0) { (channel, uid, elapsed) in
                print("Joined channel: \(channel) with uid: \(uid)")
                self.setup(videoCall: videoCall)
                completion(uid)
            }
        }
    }
    
    func leaveChannel() {
        agoraKit.leaveChannel(nil)
        print("Left channel")
    }
    
    func setup(videoCall: Bool) {
        if videoCall {
            agoraKit.enableVideo()
            agoraKit.setVideoEncoderConfiguration(AgoraVideoEncoderConfiguration(
                size: AgoraVideoDimension640x360,
                frameRate: .fps15,
                bitrate: AgoraVideoBitrateStandard,
                orientationMode: .adaptative,
                mirrorMode: .auto
            ))
            agoraKit.setChannelProfile(.liveBroadcasting)
            agoraKit.setClientRole(.broadcaster)
        } else {
            agoraKit.setChannelProfile(.communication)
        }
        agoraKit.enableAudio()
    }
}

extension AgoraManager: AgoraRtcEngineDelegate {
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        print("New user joined with uid: \(uid)")
        DispatchQueue.main.async {
            self.callManager?.startCallTimer()
            UIApplication.shared.isIdleTimerDisabled = true
        }
        
        for delegate in delegates.allObjects {
            (delegate as? AgoraRtcEngineDelegate)?.rtcEngine?(engine, didJoinedOfUid: uid, elapsed: elapsed)
        }
        
        callManager?.answered = true
        if let provider = provider, let callId = callId {
            provider.reportOutgoingCall(with: callId, connectedAt: Date())
        }
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        print("New user joined channel: \(channel) with uid: \(uid)")
        
        for delegate in delegates.allObjects {
            (delegate as? AgoraRtcEngineDelegate)?.rtcEngine?(engine, didJoinChannel: channel, withUid: uid, elapsed: elapsed)
        }
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didLeaveChannelWith stats: AgoraChannelStats) {
        print("New user left channel with stats: \(stats)")
        
        for delegate in delegates.allObjects {
            (delegate as? AgoraRtcEngineDelegate)?.rtcEngine?(engine, didLeaveChannelWith: stats)
        }
        
        if let provider = provider, let callId = callId {
            provider.reportCall(with: callId, endedAt: Date(), reason: .declinedElsewhere)
        }
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        print("Agora Error: \(errorCode.rawValue)")
    }
    
    func generateAgoraToken(uid: Int, channelName: String, completion: @escaping (String?) -> Void) {
        let url = URL(string: "https://us-central1-skillify-loviagin.cloudfunctions.net/generateAgoraToken")
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let parameters: [String: Any] = ["uid": String(uid), "channelName": channelName]
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Ошибка при запросе токена: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            if let response = response as? HTTPURLResponse {
                print("Статус ответа: \(response.statusCode)")
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("Ответ: \(responseString)")
                }
            }
            
            guard let data = data, let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                print("Ошибка при получении данных или неверный статус ответа")
                completion(nil)
                return
            }
            
            if let tokenDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: String],
               let token = tokenDict["token"] {
                print("Токен получен: \(token)")
                completion(token)
            } else {
                print("Ошибка декодирования токена")
                completion(nil)
            }
        }
        
        task.resume()
    }
}
