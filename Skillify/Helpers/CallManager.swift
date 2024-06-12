//
//  CallManager.swift
//  Skillify
//
//  Created by Ilia Loviagin on 5/22/24.
//

import CallKit
import AgoraRtcKit
import FirebaseAuth
import FirebaseFirestore
import AVFoundation

class CallManager: NSObject, ObservableObject {
    @Published var callId: UUID?
    @Published var channelName: String?
    @Published var token: String? // not generating in setCall
    @Published var receiver: User? // получатель звонка
    @Published var handler: User? // кто звонит
    @Published var incoming = false
    @Published var video = false
    @Published var muted = false
    @Published var show = false
    @Published var status: String?
    @Published var answered = false
    
    private let callController = CXCallController()
    private var provider: CXProvider
    private var callTimer: Timer? = nil
    private var callTimeSeconds = 0
    
    var agoraManager: AgoraManager!
    
    override init() {
        let configuration = CXProviderConfiguration()
        configuration.supportedHandleTypes = [.generic]
        configuration.supportsVideo = true
        configuration.maximumCallsPerCallGroup = 1
        configuration.maximumCallGroups = 1
        //        configuration.ringtoneSound = "ringtone.wav"
        if let icon = UIImage(named: "sk"), let iconData = icon.pngData() {
            configuration.iconTemplateImageData = iconData
        }
        
        provider = CXProvider(configuration: configuration)
        super.init() 
        agoraManager = AgoraManager(appId: "794acf61e12e4e49bb9d2e7789cf05b9", self)
        provider.setDelegate(self, queue: nil)
    }
    
    // only for outgoing calls
    func setCall(channelName: String, receiver: User, handler: User, video: Bool = false, completion: () -> Void) {
        callId = UUID()
        self.channelName = channelName
        self.receiver = receiver
        self.handler = handler
        self.video = video
        self.status = "Starting call..."
        print("starting call...")
        completion()
        sendMessage()
    }
    
    func sendMessage() {
        if let chat = handler?.messages.first(where: { $0.keys.contains(receiver?.id ?? "") }) {
            let newChat = Chat(id: UUID().uuidString, cUid: handler?.id ?? "", time: Date().timeIntervalSince1970)
            let chatData = try? JSONEncoder().encode(newChat)
            guard let chatDictionary = try? JSONSerialization.jsonObject(with: chatData!, options: []) as? [String: Any] else {
                print("Ошибка при сериализации объекта Chat")
                return
            }
            Firestore.firestore()
                .collection("messages")
                .document(chat.values.first ?? "error")
                .updateData(["messages": FieldValue.arrayUnion([
                    chatDictionary
                ])]) { error in
                    if error != nil {
                        print("error \(error?.localizedDescription ?? "")")
                    }
                }
            Firestore.firestore()
                .collection("messages")
                .document(chat.values.first ?? "error")
                .updateData(["lastData": [handler?.id ?? "", "📞 Call", "u"], "time": Date().timeIntervalSince1970]) { error in
                    if error != nil {
                        print("error \(error?.localizedDescription)")
                    }
                }
        }
    }
    
    // only for incoming calls
    func setCall(caller: String, uuid callId: String, channelName: String, hasVideo: Bool, token: String, completion: @escaping () -> Void) {
        self.callId = UUID(uuidString: callId)
        self.channelName = channelName
        self.token = token
        self.incoming = true
        self.video = hasVideo
        self.status = "Getting call..."
        loadCallers(handler: caller, receiver: Auth.auth().currentUser!.uid) { result in
            switch result {
            case .success(let (hand, rec)):
                // Обработка загруженных документов
                self.handler = try? hand.data(as: User.self)
                self.receiver = try? rec.data(as: User.self)
                completion()
            case .failure(let error):
                // Обработка ошибки
                print("Error loading documents: \(error.localizedDescription)")
                self.status = "Error getting call. Check your internet connection"
            }
        }
    }
    
    func startCall() {
        let handle = CXHandle(type: .generic, value: handler!.first_name)
        let startCallAction = CXStartCallAction(call: callId!, handle: handle)
        startCallAction.isVideo = video
        let transaction = CXTransaction(action: startCallAction)
        agoraManager.generateAgoraToken(uid: 0, channelName: channelName!, completion: { value in
            if value != nil {
                self.token = value
                self.callController.request(transaction) { error in
                    if let error = error {
                        print("Error starting call: \(error.localizedDescription)")
                        self.status = "Error internet connection"
                    } else {
                        let update = CXCallUpdate()
                        update.remoteHandle = handle
                        update.hasVideo = self.video
                        self.provider.reportCall(with: self.callId!, updated: update)
                        Task {
                            await self.sendVoipNotification()
                        }
                        self.status = "Calling..."
                    }
                }
            } else {
                self.status = "Error internet connection"
            }
        })
        //        startCallTimer()
    }
    
    func reportIncomingCall() {
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: handler!.first_name)
        update.hasVideo = video
        
        provider.reportNewIncomingCall(with: callId!, update: update) { error in
            if let error {
                print("error here 3ruf9r \(error.localizedDescription)")
            } else {
                print("call started")
                self.show = true
            }
        }
    }
    
    private func sendVoipNotification(end: Bool = false) async {
        print("sending voip noti with end - \(end) and \(receiver!.id)")
        let parameters = [
            "contents": ["en": end ? "Call ended" : "Incoming call"],
            "app_id": "5e75a1c5-4bab-42cc-8329-b697e85d92f7",
            "include_external_user_ids": self.incoming ? [handler!.id] : [receiver!.id],
            "apns_push_type_override": "voip",
            "data": [
                "caller": handler!.id,
                "uuid": callId?.uuidString ?? "",
                "callStatus": end ? "ended" : "incoming",
                "channelName": channelName ?? "groupCall-",
                "token": token ?? "",
                "hasVideo": video
            ]
        ] as [String : Any?]
        
        let postData = try! JSONSerialization.data(withJSONObject: parameters, options: [])
        
        let url = URL(string: "https://api.onesignal.com/notifications")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 10
        request.allHTTPHeaderFields = [
            "accept": "application/json",
            "Authorization": "Basic ODI1YjIzNjMtMTg2YS00NTE0LTljNmMtM2JkNjhjNGYzMzZl",
            "content-type": "application/json"
        ]
        request.httpBody = postData
        
        let (data, _) = try! await URLSession.shared.data(for: request)
        print(String(decoding: data, as: UTF8.self))
    }
    
    func endCall() {
        print("ending")
        
        DispatchQueue.main.async {
            UIDevice.current.isProximityMonitoringEnabled = false
            UIApplication.shared.isIdleTimerDisabled = false
        }
        
        callTimer?.invalidate()
        callTimer = nil
        callTimeSeconds = 0
        
        if let callId {
            let endCallAction = CXEndCallAction(call: callId)
            let transaction = CXTransaction(action: endCallAction)
            
            callController.request(transaction) { error in
                if let error = error {
                    print("Error ending call: \(error.localizedDescription)")
                    Task {
                        await self.sendVoipNotification(end: true)
                    }
                    self.resetData()
                } else {
                    print("Call ended successfully.")
                    // Отправка уведомления о завершении звонка собеседнику
                    Task {
                        await self.sendVoipNotification(end: true)
                    }
                    self.resetData()
                }
            }
        } else {
            self.resetData()
        }
        self.status = "Ended call"
    }
    
    func toogleMute() {
        muted.toggle()
        agoraManager.agoraKit!.muteLocalAudioStream(muted)
    }
    
    private func loadCallers(handler: String, receiver: String, completion: @escaping (Result<(DocumentSnapshot, DocumentSnapshot), Error>) -> Void) {
        let db = Firestore.firestore()
        
        let docRef1 = db.collection("users").document(handler)
        let docRef2 = db.collection("users").document(receiver)
        
        let group = DispatchGroup()
        var document1: DocumentSnapshot?
        var document2: DocumentSnapshot?
        var error: Error?
        
        group.enter()
        docRef1.getDocument { (snapshot, err) in
            if let err = err {
                error = err
            } else {
                document1 = snapshot
            }
            group.leave()
        }
        
        group.enter()
        docRef2.getDocument { (snapshot, err) in
            if let err = err {
                error = err
            } else {
                document2 = snapshot
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            if let error = error {
                completion(.failure(error))
            } else if let document1 = document1, let document2 = document2 {
                completion(.success((document1, document2)))
            } else {
                // This case should not happen, but we handle it gracefully
                let error = NSError(domain: "FirestoreErrorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error"])
                completion(.failure(error))
            }
        }
    }
    
    func startCallTimer() {
        print("timer started")
        callTimeSeconds = 0 // Сброс времени звонка
        callTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.callTimeSeconds += 1
            self.status = self.formatTime(self.callTimeSeconds)
        }
    }
    
    private func formatTime(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func resetData() {
        callId = nil
        channelName = nil
        token = nil
        receiver = nil
        handler = nil
        incoming = false
        video = false
        muted = false
        show = false
        status = nil
    }
}

extension CallManager: CXProviderDelegate {
    func providerDidReset(_ provider: CXProvider) {
        print("reset")
        self.resetData()
    }
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        print("answer")
        action.fulfill()
        agoraManager.joinChannel(channel: self.channelName!, token: self.token, videoCall: self.video, provider: provider, callId: callId!) {
            action.fulfill(withDateConnected: Date())
            self.startCallTimer()
        }
    }
    
    func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {
        print("time out")
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        print("end")
        action.fulfill()
        self.endCall()
        agoraManager.leaveChannel()
    }
    
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        print("start")
        action.fulfill()
        agoraManager.joinChannel(channel: self.channelName!, token: self.token, videoCall: self.video, provider: provider, callId: callId!) {
            action.fulfill(withDateStarted: Date())
        }
    }
    
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        print("didActivate")
        do {
            if video {
                try audioSession.setCategory(.playAndRecord, mode: .videoChat)
            } else {
                try audioSession.setCategory(.playAndRecord, mode: .voiceChat)
            }
            try audioSession.setActive(true)
            DispatchQueue.main.async {
                UIDevice.current.isProximityMonitoringEnabled = true
            }
        } catch {
            self.status = "Something went wrong"
        }
    }
    
    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        print("deactivate")
        do {
            try audioSession.setActive(false)
        } catch {
            self.status = "Something went wrong"
        }
        agoraManager.agoraKit!.disableAudio()
    }
}

extension CallManager {
    static var mock: CallManager {
        let manager = CallManager()
        return manager
    }
}
