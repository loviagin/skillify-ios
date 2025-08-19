//
//  HorizontalCourseView.swift
//  Skillify
//
//  Created by Ilia Loviagin on 11/19/24.
//

import SwiftUI
import Kingfisher

struct HorizontalCourseView: View {
    @State var course: Course?
    
    var body: some View {
        HStack(spacing: 15) {
            if let preview = course?.preview, let url = URL(string: preview) {
                KFImage(url)
                    .resizable()
                    .placeholder {
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .foregroundStyle(.blue)
                    }
                    .scaledToFill()
                    .frame(width: 50, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundStyle(.blue)
            }
            
            VStack(alignment: .leading) {
                if let title = course?.title {
                    Text(title)
                        .bold()
                }
                
                if let description = course?.description {
                    Text(description)
                        .font(.caption)
                }
            }
            
            Spacer()
            
            if let rating = course?.rating {
                HStack(spacing: 5) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    
                    Text("\(String(format: "%.1f", rating))")
                        .font(.headline)
                }
            }
        }
    }
}

#Preview {
    HorizontalCourseView(course: Course(title: "Welcome", description: "Welcome course"))
}
