//
//  PhoneRegisterView.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 19.12.2023.
//

import SwiftUI
import Combine

struct PhoneRegisterView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var phone = ""
    @State private var verifyCode = ""
    @State private var isShowingAlert = false
    
    @State private var isEnterCode = false
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                Text("Login to your account")
                    .foregroundColor(.primary)
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 10)
                Text("Using your phone number")
                    .padding(.bottom, 20)
                
                Text("Your phone")
                TextField("Enter your phone number", text: $phone)
                    .keyboardType(.phonePad)
                    .autocapitalization(.none)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.bottom, 10)
                    .onReceive(Just(phone)) { newValue in
                        let filtered = newValue.filter { "0123456789".contains($0) }
                        if filtered != newValue {
                            self.phone = filtered
                        }
                        
                        // Применяем маску форматирования
                        self.phone = self.applyPhoneMask(to: filtered)
                    }
                VStack(alignment: .leading){
                    if isEnterCode {
                        Text("Enter the verification code")
                        TextField("* * * * * *", text: $verifyCode)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Button{
                            isEnterCode = false
                        } label: {
                            Text("Resend code")
                        }
                    }
                }
                Button {
                    if isEnterCode { // login
                        authViewModel.loginViaPhoneFirebase(verificationCode: verifyCode)
                    } else { // send a code
                        isEnterCode = true
                        authViewModel.signInWithPhone(phoneNumber: phone)
                    }
//                    Task {
                    //                        try await authViewModel.createUser(email: email, pass: password)
                    //                    }
                } label: {
                    HStack{
                        Spacer()
                        Text(isEnterCode ? "Login" : "Send a code")
                        //                            .font(.title3)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .frame(width: .infinity, height: 40)
                    .background(.blue)
                    .cornerRadius(15)
                    .padding(.top, 10)
                }
                .alert(isPresented: $isShowingAlert) {
                    Alert(title: Text("Error"), message: Text(authViewModel.errorMessage ?? "Unknown error"), dismissButton: .default(Text("OK")))
                }
                .onChange(of: authViewModel.errorMessage) { _ in
                    isShowingAlert = authViewModel.errorMessage != nil
                }
                Spacer()
            }
            .padding()
        }
    }
    
    func applyPhoneMask(to rawPhoneNumber: String) -> String {
        let numbersOnly = rawPhoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        let maxDigits = 15 // Установите максимальное ожидаемое количество цифр
        var result = ""
        var index = numbersOnly.startIndex // Указатель на текущий символ строки
        
        // Добавляем маску "(XXX) XXX-XXXX" только если количество цифр не превышает 10
        let mask = numbersOnly.count <= 11 ? "+X (XXX) XXX-XXXX" : "XXXXXXXXXXXXXXX" // Расширенная маска без форматирования
        
        for ch in mask where index < numbersOnly.endIndex {
            if ch == "X" {
                result.append(numbersOnly[index])
                index = numbersOnly.index(after: index)
            } else if numbersOnly.count <= 11 { // Добавляем скобки, пробелы и тире только для первых 10 цифр
                result.append(ch)
            }
        }
        
        // Если количество цифр больше 10, добавляем оставшиеся цифры без форматирования
        while index < numbersOnly.endIndex {
            result.append(numbersOnly[index])
            index = numbersOnly.index(after: index)
        }
        
        return result
    }
    
}

#Preview {
    PhoneRegisterView()
}
