//
//  BottomBarChatView.swift
//  Skillify
//
//  Created by Ilia Loviagin on 10/17/24.
//

import SwiftUI
import AVFoundation

struct BottomBarChatView: View {
    @Binding var text: String
    @FocusState.Binding var focusing: ChatFocus?
    var sendAction: () -> Void

    @Binding var selectedImages: [UIImage]
    @Binding var selectedVideos: [URL]
    @Binding var audioFileURL: URL?
    @Binding var audioLevels: [Float]
    
    @State private var isRecording = false
    @State private var showAttach = false // false
    @State private var audioRecorder: AVAudioRecorder?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var timer: Timer?
    
    @State var showPhotoPicker = false
    @State var showVideoPicker = false

    var body: some View {
        VStack {
            if !selectedImages.isEmpty {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(Array(selectedImages.enumerated()), id: \.element) { index, image in
                            ZStack {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 15))
                                    .clipped()

                                Button {
                                    selectedImages.remove(at: index)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 24, height: 24)
                                        .foregroundColor(.white)  // Цвет крестика
                                        .background(Circle().fill(Color.gray))  // Серый фон для круга
                                }
                            }
                        }
                    }
                }
                .scrollIndicators(.never)
            }

            if !selectedVideos.isEmpty {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(Array(selectedVideos.enumerated()), id: \.element) { index, videoURL in
                            ZStack {
                                VideoThumbnailView(videoURL: videoURL)  // Новый компонент для видео миниатюры
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 15))
                                    .clipped()
                                
                                Button {
                                    selectedVideos.remove(at: index)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 24, height: 24)
                                        .foregroundColor(.white)  // Цвет крестика
                                        .background(Circle().fill(Color.gray))  // Серый фон для круга
                                }
                            }
                        }
                    }
                }
                .scrollIndicators(.never)
            }

            HStack(spacing: 10) {
                if audioFileURL != nil {
                    HStack {
                        Button {
                            withAnimation {
                                stopPlaying()
                                audioFileURL = nil
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .resizable()
                                .frame(width: 23, height: 23)
                                .tint(.red)
                        }
                        
                        Button {
                            playRecording()
                        } label: {
                            Image(systemName: "play.circle.fill")
                                .resizable()
                                .frame(width: 23, height: 23)
                        }
                    }
                } else if !isRecording {
                    Button {
                        withAnimation {
                            showAttach = true
                        }
                    } label: {
                        Image(systemName: "paperclip")
                            .resizable()
                            .frame(width: 23, height: 23)
                    }
                }
                
                if isRecording || audioFileURL != nil {
                    AudioWaveformView(levels: audioLevels)
                        .frame(height: 40)
                        .padding()
                } else {
                    TextField("Type", text: $text, prompt: Text("Type..."), axis: .vertical)
                        .padding(5)
                        .background(.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .lineLimit(4)
                        .focused($focusing, equals: ChatFocus.textField)
                }
                
                if text.isEmpty && selectedImages.isEmpty && selectedVideos.isEmpty && audioFileURL == nil {
                    Image(systemName: "mic")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 23)
                        .foregroundStyle(.blue)
                        .background(
                            Circle()
                                .stroke(isRecording ? Color.blue : Color.clear, lineWidth: isRecording ? 8 : 0)  // Обводка вокруг кнопки
                                .scaleEffect(isRecording ? 1.2 : 1.0)
                                .opacity(isRecording ? 1.0 : 0.0)
                                .animation(.easeInOut(duration: 0.3), value: isRecording)
                        )
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    if !isRecording {
                                        startRecording()
                                    }
                                }
                                .onEnded { _ in
                                    stopRecording()
                                }
                        )
                } else {
                    Button {
                        stopPlaying()
                        sendAction()
                    } label: {
                        Image(systemName: "paperplane")
                            .resizable()
                            .frame(width: 23, height: 23)
                    }
                }
            }
        }
        .sheet(isPresented: $showAttach) {
            VStack {
                Text("Share Content")
                    .font(.title3)
                    .bold()
                    .padding(.top)
                
                List {
                    Button {
                        withAnimation {
                            showAttach = false
                            showPhotoPicker = true
                            print("photos 1")
                        }
                    } label: {
                        HStack(spacing: 15) {
                            IconElementView(name:  "photo")
                            
                            VStack(alignment: .leading) {
                                Text("Photo")
                                    .bold()
                                
                                Text("Select photos to share")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    Button {
                        withAnimation {
                            showAttach = false
                            showVideoPicker = true
                        }
                    } label: {
                        HStack(spacing: 15) {
                            IconElementView(name: "video")
                            
                            VStack(alignment: .leading) {
                                Text("Video")
                                    .bold()
                                
                                Text("Select videos to share")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
//                    Button {
//                        withAnimation {
//                            showAttach = false
//                        }
//                    } label: {
//                        HStack(spacing: 15) {
//                            IconElementView(name: "calendar")
//                            
//                            VStack(alignment: .leading) {
//                                Text("Custom meeting")
//                                    .bold()
//                                
//                                Text("Set the meeting date and get a notification")
//                                    .font(.caption)
//                                    .foregroundStyle(.secondary)
//                            }
//                        }
//                    }
                }
                .listStyle(.inset)
                .listSectionSpacing(15)
                
                Spacer()
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showVideoPicker) {
            withAnimation {
                showVideoPicker = false
            }
        } content: {
            VideoChatPicker(selectedVideos: $selectedVideos)
                .ignoresSafeArea()
        }
        .sheet(isPresented: $showPhotoPicker) {
            withAnimation {
                showPhotoPicker = false
                print("photos 2")
            }
        } content: {
            ImageChatPicker(selectedImages: $selectedImages)
                .ignoresSafeArea()
        }
        .onChange(of: selectedImages) { oldValue, newValue in
            showPhotoPicker = false
        }
        .onChange(of: selectedVideos) { oldValue, newValue in
            showVideoPicker = false
        }
    }
    
    private func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            
            let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioFilename = documentDirectory.appendingPathComponent("voiceMessage.m4a")
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.isMeteringEnabled = true  // Включаем измерение уровня громкости
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()
            
            isRecording = true
            audioLevels = []  // Очищаем данные перед новой записью
            
            // Запускаем таймер для регулярного обновления уровня громкости
            timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                self.updateAudioLevels()
            }
        } catch {
            print("Failed to start recording: \(error.localizedDescription)")
        }
    }
    
    private func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        
        if let recorder = audioRecorder {
            audioFileURL = recorder.url
        }
        
        // Останавливаем таймер
        timer?.invalidate()
        timer = nil
    }
    
    private func playRecording() {
        guard let audioFileURL = audioFileURL else { return }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioFileURL)
            audioPlayer?.play()
        } catch {
            print("Failed to play recording: \(error.localizedDescription)")
        }
    }
    
    private func stopPlaying() {
        guard audioFileURL != nil else { return }
        
        audioPlayer?.stop()  // Останавливаем воспроизведение и сбрасываем на начало
        audioPlayer?.currentTime = 0  // Сбрасываем текущее время воспроизведения на начало файла
    }
    
    private func updateAudioLevels() {
        guard let recorder = audioRecorder else { return }
        
        recorder.updateMeters()
        let level = recorder.averagePower(forChannel: 0)
        let normalizedLevel = normalizedAudioLevel(level: level)
        audioLevels.append(normalizedLevel)
        
        // Ограничиваем размер массива до 100 элементов для оптимальной визуализации
        if audioLevels.count > 100 {
            audioLevels.removeFirst()
        }
    }
    
    private func normalizedAudioLevel(level: Float) -> Float {
        let minLevel: Float = -80
        let range = 80
        let outRange: Float = 1.0
        
        if level < minLevel {
            return 0.0
        } else {
            return (outRange * (level + abs(minLevel))) / Float(range)
        }
    }
}
