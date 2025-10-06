//
//  LoadingView.swift
//  Skillify
//
//  Created by Ilia Loviagin on 10/6/25.
//

import SwiftUI

struct LoadingView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var isAnimating = false
    @State private var rotation = 0.0
    @State private var scale = 0.8
    @State private var opacity = 0.0
    
    var body: some View {
        ZStack {
            // Градиентный фон с адаптацией к темной теме
            LinearGradient(
                colors: colorScheme == .dark ? [
                    Color(red: 0.1, green: 0.1, blue: 0.15),
                    Color(red: 0.15, green: 0.12, blue: 0.2),
                    Color(red: 0.08, green: 0.08, blue: 0.12)
                ] : [
                    Color(red: 0.95, green: 0.85, blue: 0.95),
                    Color(red: 0.85, green: 0.90, blue: 1.0),
                    Color.white
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Декоративные круги на фоне
            GeometryReader { geometry in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.newPink.opacity(colorScheme == .dark ? 0.25 : 0.15),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 300, height: 300)
                    .blur(radius: 30)
                    .offset(x: -100, y: -150)
                    .scaleEffect(isAnimating ? 1.2 : 0.8)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(colorScheme == .dark ? 0.2 : 0.1),
                                Color.clear
                            ],
                            startPoint: .bottomTrailing,
                            endPoint: .topLeading
                        )
                    )
                    .frame(width: 250, height: 250)
                    .blur(radius: 25)
                    .offset(x: geometry.size.width - 150, y: geometry.size.height - 200)
                    .scaleEffect(isAnimating ? 0.9 : 1.1)
            }
            
            // Основной контент
            VStack(spacing: 30) {
                Spacer()
                
                // Логотип с анимацией
                ZStack {
                    // Пульсирующий круг позади логотипа
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.newPink.opacity(colorScheme == .dark ? 0.4 : 0.3),
                                    Color.blue.opacity(colorScheme == .dark ? 0.3 : 0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .scaleEffect(isAnimating ? 1.3 : 0.8)
                        .opacity(isAnimating ? (colorScheme == .dark ? 0.4 : 0.3) : (colorScheme == .dark ? 0.7 : 0.6))
                    
                    // Логотип
                    Image(.newLogo)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 220, height: 80)
                        .scaleEffect(scale)
                        .opacity(opacity)
                }
                
                // Анимированный текст
                VStack(spacing: 12) {
                    Text("Learnsy")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: colorScheme == .dark ? [
                                    Color.newPink.opacity(0.9),
                                    Color.blue.opacity(0.9)
                                ] : [.newPink, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .opacity(opacity)
                    
                    Text("Sharpen your skills anytime, connecting with people across the globe")
                        .font(.subheadline)
                        .foregroundStyle(colorScheme == .dark ? .white.opacity(0.7) : .secondary)
                        .multilineTextAlignment(.center)
                        .opacity(opacity * 0.8)
                }
                .padding(.horizontal, 40)
                
                // Анимированный индикатор загрузки
                HStack(spacing: 8) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.newPink, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 12, height: 12)
                            .scaleEffect(isAnimating ? 1.0 : 0.5)
                            .animation(
                                .easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                                value: isAnimating
                            )
                    }
                }
                .padding(.top, 20)
                .opacity(opacity)
                
                Spacer()
                Spacer()
            }
        }
        .onAppear {
            // Запускаем все анимации
            withAnimation(.easeOut(duration: 0.8)) {
                opacity = 1.0
                scale = 1.0
            }
            
            withAnimation(
                .easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
            ) {
                isAnimating = true
            }
            
            withAnimation(
                .linear(duration: 20)
                .repeatForever(autoreverses: false)
            ) {
                rotation = 360
            }
        }
    }
}

#Preview("Light Mode") {
    LoadingView()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    LoadingView()
        .preferredColorScheme(.dark)
}

