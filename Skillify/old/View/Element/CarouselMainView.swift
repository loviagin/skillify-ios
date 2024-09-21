//
//  CarouselMainView.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 19.12.2023.
//
import SwiftUI

struct CarouselMainView: View {
    // Состояние для управления текущим выбранным индексом
    @State private var selection = 0
    
    // Таймер для автоматической прокрутки
    let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            // TabView для создания слайдера
            TabView(selection: $selection) {
                // Вставьте свои изображения и установите им тэги
                Image("image1")
                    .resizable()
                    .tag(0)
                Image("image2")
                    .resizable()
                    .tag(1)
                Image("image3")
                    .resizable()
                    .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)) // Стиль с точками для индикации страниц
            .onReceive(timer) { _ in
                // Автоматическая прокрутка изображений
                withAnimation {
                    selection = (selection + 1) % 3 // Замените 3 на количество изображений
                }
            }
            
            // Остальная часть вашего интерфейса
        }
        .background(Color.clear)
        .ignoresSafeArea()
    }
}

#Preview {
    CarouselMainView()
}
