//
//  ShareProfileView.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 19.12.2023.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct ShareProfileView: View {
    @State var user: User
    
    @State private var showText = false
    
    var body: some View {
        VStack {
            AvatarView(avatarUrl: user.urlAvatar)
            
            Text("\(user.first_name) \(user.last_name)")
                .font(.title)
                .bold()
            
            if let qrImage = generateQRCode(from: "skillify://@\(user.nickname)") {
                Image(uiImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .background(Color.clear)
            } else {
                Text("Failed to generate QR code")
            }
            
            HStack(spacing: 30) {
                Text("@")
                    .padding()
                    .background(.gray)
                    .foregroundStyle(.white)
                
                Text(user.nickname)
                
                Spacer()
                
                Button {
                    UIPasteboard.general.string = "skillify://@\(user.nickname)"
                    showText = true
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showText = false
                    }
                } label: {
                    Image(systemName: "doc.on.doc")
                        .padding()
                        
                }
            }
            .background(.lGray)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .padding(.horizontal, 30)
            .padding(.vertical)
            
            if showText {
                Text("Copied")
                    .font(.caption)
            }
        }
        .padding(.bottom)
        .frame(maxHeight: .infinity)
        .background(LinearGradient(colors: [.brandBlue.opacity(0.2), .redApp.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
        .ignoresSafeArea()
    }
    
    func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        
        if let outputImage = filter.outputImage {
            let colorFilter = CIFilter.falseColor()
            colorFilter.inputImage = outputImage
            colorFilter.color0 = CIColor.black // Цвет QR-кода
            colorFilter.color1 = CIColor.clear // Прозрачный фон
            
            if let coloredImage = colorFilter.outputImage {
                if let cgImage = context.createCGImage(coloredImage, from: coloredImage.extent) {
                    return UIImage(cgImage: cgImage)
                }
            }
        }
        
        return nil
    }
}

#Preview {
    ShareProfileView(user: User(first_name: "Elian", last_name: "Broun", nickname: "loveyourself"))
}
