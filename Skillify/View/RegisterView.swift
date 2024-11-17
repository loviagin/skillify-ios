//
//  RegisterView.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 19.12.2023.
//

import SwiftUI
import GoogleSignIn
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import Firebase
import AuthenticationServices
import CryptoKit

enum ImageType {
    case systemName(String)
    case name(String)
}

struct RegisterView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var navigateToEmail = false
    @State private var navigateToPhone = false
    @State private var navigateToGoogle = false
    
    @State var isLoading = false
    @Binding var navigateToRegister: Bool
    @State var isUserAuthenticated = false
    
    @State private var isRegisterAllowed = true
    
    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    ProgressView()
                        .frame(width: 30, height: 30)
                        .foregroundStyle(.brandBlue)
                }
                if isRegisterAllowed {
                    HStack{
                        Spacer()
                        Button {
                            navigateToRegister = false
                        } label: {
                            Image(systemName: "xmark")
                                .padding(.trailing, 25)
                                .padding(.top, 20)
                                .foregroundColor(.primary)
                                .symbolRenderingMode(.hierarchical)
                                .font(.title3)
                        }
                    }
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 60)
                        .padding(.top, 20)
                    Text("Create an account")
                        .font(.title)
                    Text("Choose a registration method convenient for you")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)

                    ButtonRegisterView(action: {
                        navigateToEmail = true
                    },
                                       text: "Continue with Email",
                                       image: .systemName("envelope"),
                                       colorGround: .gray,
                                       colorText: .white)
                    .background(
                        NavigationLink(
                            destination: EmailRegistrationView(),
                            isActive: $navigateToEmail) {
                                EmptyView()
                            }
                            .hidden()
                    )
                    
                    OtherMethodsToSignInView(isLoading: $isLoading)
                    
                    Spacer()
                } else {
                    Text("Sorry")
                    Text("Administrator was disabled registration")
                    Text("Come back later")
                }
            }
            .onChange(of: Auth.auth().currentUser) { _, newValue in
                isUserAuthenticated = newValue != nil
            }
            .onAppear {
                Firestore.firestore().collection("admin").document("system").getDocument { doc, error in
                    if error != nil {
                        print("error while load admin")
                    } else {
                        self.isRegisterAllowed = doc?.get("allowRegistration") as? Bool ?? true
                    }
                }
            }
        }
    }
}

#Preview {
    RegisterView(navigateToRegister: .constant(true))
}

struct OtherMethodsToSignInView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State var isUserAuthenticated = false
    @StateObject var signInWithAppleManager = SignInWithAppleManager()
    
    @Binding var isLoading: Bool
    
    var body: some View {
        NavigationLink(destination: PhoneRegisterView()) {
            Image(systemName: "phone")
                .padding(.leading, 20)
            Spacer()
            Text("Continue with Phone")
            Spacer()
        }
        .frame(width: 300, height: 45)
        .background(.blue)
        .foregroundColor(.white)
        .cornerRadius(25)
        .padding(.top, 10)
        
        ButtonRegisterView(action: {
            isLoading = true
            authViewModel.signInWithGoogle() { error in
                if let error {
                    print(error)
                }
                isLoading = false
            }
        },
                           text: "Continue with Google",
                           image: .name("googleIcon"),
                           colorGround: .lGray,
                           colorText: .blue)
        SignInWithAppleButton(
            .signIn,
            onRequest: { request in
                isLoading = true
                let nonce = signInWithAppleManager.randomNonceString()
                signInWithAppleManager.currentNonce = nonce
                request.requestedScopes = [.fullName, .email]
                request.nonce = signInWithAppleManager.sha256(nonce)
            },
            onCompletion: { result in
                switch result {
                case .success(let authorization):
                    signInWithAppleManager.handleAuthorization(authorization)
                case .failure(let error):
                    signInWithAppleManager.handleAuthorizationError(error)
                }
                isLoading = false
            }
        )
        .frame(width: 300, height: 45)
        .cornerRadius(25)
        .padding()
        .navigationDestination(isPresented: $isUserAuthenticated) {
            ContentView()
        }
        .onAppear {
            signInWithAppleManager.authViewModel = authViewModel
        }
    }
}

struct ButtonRegisterView: View {
    var action: () -> Void
    var text: String
    var image: ImageType
    var colorGround: Color
    var colorText: Color
    
    var body: some View {
        Button(action: action) {
            imageComponent
                .padding(.leading, 20)
            Spacer()
            Text(text)
            Spacer()
        }
        .frame(width: 300, height: 45)
        .background(colorGround)
        .foregroundColor(colorText)
        .cornerRadius(25)
        .padding(.top, 10)
    }
    
    @ViewBuilder
    private var imageComponent: some View {
        switch image {
        case .systemName(let systemName):
            Image(systemName: systemName)
        case .name(let name):
            Image(name)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
        }
    }
}
