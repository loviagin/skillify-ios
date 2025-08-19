//
//  MainOnboardingView.swift
//  Skillify
//
//  Created by Ilia Loviagin on 11/17/24.
//

import SwiftUI

struct MainOnboardingView: View {
    @AppStorage("pointIntroduced") var pointIntroduced = true
    
    @State private var selections: OnBoardingViews = .coursesIntroduce
    
    var body: some View {
        VStack {
//            HStack {
//                Spacer()
//                
//                Button("Skip") {
//                    pointIntroduced = false
//                }
//            }
//            .padding()
            
            TabView(selection: $selections) {
                PointsIntroduceView()
                    .tag(OnBoardingViews.coursesIntroduce)
                
//                PointsIntroduceView()
//                    .tag(OnBoardingViews.coursesIntroduce)
            }
            .tabViewStyle(.page)
            
            Button {
                withAnimation {
                    if selections == .pointsIntroduce {
                        selections = .coursesIntroduce
                    } else {
                        pointIntroduced = false
                    }
                }
            } label: {
                Text(selections == .pointsIntroduce ? "Next" : "Let's go")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
            }
            .padding()
            
//            HStack {
//                Spacer()
//                
//                Circle()
//                    .fill(selections == .pointsIntroduce ? Color.blue : Color.gray)
//                    .frame(width: 10, height: 10)
//                
//                Circle()
//                    .fill(selections == .coursesIntroduce ? Color.blue : Color.gray)
//                    .frame(width: 10, height: 10)
//                
//                Spacer()
//            }
        }
    }
}

enum OnBoardingViews {
    case pointsIntroduce, coursesIntroduce
}

#Preview {
    MainOnboardingView()
}
