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
                    //                    .padding(.top, 1)
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
            //                .padding(.leading, 10)
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
            AccountView()
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
            //                .padding(.leading, 10)
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

// SignInWithAppleManager.swift
class SignInWithAppleManager: NSObject, ObservableObject {
//    @Published var userSession: Firebase.User?
    var currentNonce: String?
    var authViewModel: AuthViewModel?
    
    func handleAuthorization(_ authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let nonce = currentNonce,
              let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            return
        }
        
        let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                  idToken: idTokenString,
                                                  rawNonce: nonce)
        Auth.auth().signIn(with: credential) { [weak self] (authResult, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            DispatchQueue.main.async {
                if let user = authResult?.user {
                    var firstName: String = ""
                    var lastName: String = ""
                    
                    if let fullName = appleIDCredential.fullName {
                        let name = PersonNameComponentsFormatter().string(from: fullName)
                        
                        if name.split(separator: " ").count == 1 {
                            firstName = name
                        } else {
                            firstName = String(name.split(separator: " ").first ?? "")
                            lastName = String(name.split(separator: " ").last ?? "")
                        }
                    }

                    Task {
                        // Capture `self` weakly to avoid a retain cycle
                        [weak self] in
                        guard let self = self else { return }
                        await self.authViewModel?.registerUserAndLoadProfile(
                            uid: user.uid, email: user.email ?? "", firstName: firstName, lastName: lastName, phone: user.phoneNumber ?? ""
                        )
                    }
                }
            }
        }
    }
    
    func handleAuthorizationError(_ error: Error) {
        print(error.localizedDescription)
    }
    
    func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap { return String(format: "%02x", $0) }.joined()
        
        return hashString
    }
}

extension SignInWithAppleManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        handleAuthorization(authorization)
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        handleAuthorizationError(error)
    }
}

extension SignInWithAppleManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return UIApplication.shared.windows.first { $0.isKeyWindow }!
    }
}
