//
//  CoursesView.swift
//  Skillify
//
//  Created by Ilia Loviagin on 6/2/24.
//

import SwiftUI

struct CoursesView: View {
    @EnvironmentObject private var viewModel: AuthViewModel
    @StateObject private var coursesViewModel = CoursesViewModel()
    
    @State private var activeTab: CourseType = .all
    @State private var isCartOpen = false
    
    @State var show: String? = nil
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Image("logoCourses")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150)
                        Spacer()
                        Button {
                            isCartOpen = true
                        } label: {
                            Image(systemName: "cart")
                        }
                        
                    }
                }
                
                if !coursesViewModel.videos.isEmpty {
                    Section {
                        ScrollView(.horizontal) {
                            LazyHStack(spacing: 15) {
                                ForEach(coursesViewModel.videos, id: \.id) { it in
                                    if let image = coursesViewModel.getThumbnailFromVideo(videoURL: it.url) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 90, height: 100)
                                            .clipped()
                                            .clipShape(RoundedRectangle(cornerRadius: 15))
                                            .overlay (
                                                RoundedRectangle(cornerRadius: 15)
                                                    .stroke(LinearGradient(colors: [.brandBlue, .redApp], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 4)
                                            )
                                            .onTapGesture {
                                                show = it.url
                                            }
                                    }
                                }
                            }
                            .padding(.leading, 5)
                        }
                    }
                }
                
                Section {
                    VStack {
                        if coursesViewModel.courses.isEmpty {
                            Text("No courses")
                        }
                    }
                } header: {
                    Picker("", selection: $activeTab) {
                        Text("All courses").tag(CourseType.all)
                        Text("New").tag(CourseType.new)
                        Text("My courses").tag(CourseType.mine)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .listStyle(.plain)
            .onAppear {
                if let courses = viewModel.currentUser?.courses, !courses.isEmpty {
                    activeTab = .mine
                }
                show = nil
            }
            .navigationDestination(isPresented: .constant(show != nil), destination: { VideoScrollsView(currentVideo: show ?? "") } )
        }
    }
    
    private enum CourseType {
        case mine
        case all
        case new
    }
}

#Preview {
    CoursesView()
        .environmentObject(AuthViewModel.mock)
        .environmentObject(CoursesViewModel.mock)
}
