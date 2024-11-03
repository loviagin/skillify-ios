//
//  AudioMessageView.swift
//  Skillify
//
//  Created by Ilia Loviagin on 10/17/24.
//

import SwiftUI
import AVFoundation

struct AudioMessageView: View {
    @State private var isPlaying = false
    @State private var audioPlayer: AVAudioPlayer?
    @State var audioLevels: [Float] = []  // Уровни громкости для отображения
    @State var isCurrent: Bool
    let audioURL: URL  // Ссылка на аудиофайл
    
    private var coordinator: AudioPlayerCoordinator
    
    init(audioURL: URL, audioLevels: [Float], current: Bool) {
        self.isCurrent = current
        self.audioURL = audioURL
        self.audioLevels = audioLevels
        self.coordinator = AudioPlayerCoordinator()
    }

    var body: some View {
        HStack {
            Button(action: {
                isPlaying ? pauseAudio() : playAudio()
            }) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(isCurrent ? .white : .blue)
            }

            AudioWaveformView(levels: audioLevels, isCurrent: isCurrent)
                .frame(height: 40)
                .padding()
        }
        .onAppear {
            setupAudioPlayer()
        }
        .onDisappear {
            stopAudio()
        }
    }

    // Настраиваем аудиоплеер
    private func setupAudioPlayer() {
        // Асинхронно загружаем данные с помощью URLSession
        let task = URLSession.shared.dataTask(with: audioURL) { data, response, error in
            guard let data = data, error == nil else {
                print("Error loading audio file: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            // Выполняем дальнейшие действия на главном потоке
            DispatchQueue.main.async {
                do {
                    self.audioPlayer = try AVAudioPlayer(data: data)
                    self.audioPlayer?.isMeteringEnabled = true
                    self.audioPlayer?.delegate = self.coordinator  // Устанавливаем делегат через координатор
                    self.coordinator.onFinishPlaying = {
                        self.isPlaying = false
                    }
                } catch {
                    print("Error initializing audio player: \(error.localizedDescription)")
                }
            }
        }
        
        task.resume()  // Начинаем загрузку данных
    }

    // Запуск воспроизведения аудио
    private func playAudio() {
        audioPlayer?.play()
        isPlaying = true
    }

    // Пауза аудио
    private func pauseAudio() {
        audioPlayer?.pause()
        isPlaying = false
    }

    // Остановка аудио при завершении
    private func stopAudio() {
        audioPlayer?.stop()
        isPlaying = false
    }
}
