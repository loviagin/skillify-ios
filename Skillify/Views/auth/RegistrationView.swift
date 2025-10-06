//
//  RegistrationView.swift
//  Skillify
//
//  Created by Ilia Loviagin on 10/5/25.
//

import SwiftUI
import PhotosUI

struct RegistrationView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    @State var draft: AppUserDraft?
    
    @State private var firstName: String = ""
    @State private var username: String = ""
    @State private var birthDate: Date = Calendar.current.date(byAdding: .year, value: -12, to: Date()) ?? Date()
    @State private var email: String = ""
    @State private var avatarUrl: String? = nil
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    
    // Focus management
    @FocusState private var focusedField: Field?
    
    enum Field {
        case firstName
        case username
    }
    
    // Avatar picker
    @State private var selectedItem: PhotosPickerItem?
    @State private var avatarImage: UIImage?
    @State private var showImagePicker = false
    @State private var showPresetsAvatar = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Title
                Text("Create an Account")
                    .font(.title)
                    .fontWeight(.bold)
                
                // Avatar picker
                VStack(spacing: 12) {
                    ZStack(alignment: .bottomTrailing) {
                        AvatarView(avatarImage: $avatarImage, avatarUrl: $avatarUrl)
                        
                        Menu {
                            Button("Gallery", systemImage: "photo.badge.plus") {
                                avatarUrl = nil
                                showImagePicker = true
                            }
                            
                            Divider()
                            
                            Button("Preset avatars", systemImage: "person.circle") {
                                avatarImage = nil
                                showPresetsAvatar = true
                            }
                        } label: {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.white)
                                .frame(width: 36, height: 36)
                                .background(Color.newBlue)
                                .clipShape(Circle())
                                .overlay {
                                    Circle()
                                        .stroke(Color.white, lineWidth: 3)
                                }
                        }
                    }
                    
                    Text("Add avatar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 10)
                
                // Form fields
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("First name")
                            .font(.body)
                            .fontWeight(.medium)
                        
                        TextField("Enter your First name", text: $firstName)
                            .textFieldStyle(CustomTextFieldStyle())
                            .focused($focusedField, equals: .firstName)
                            .submitLabel(.next)
                            .onSubmit {
                                focusedField = .username
                            }
                            .onChange(of: firstName) { _, newValue in
                                if newValue.count > Limits.maxNameLength {
                                    firstName = String(newValue.prefix(50))
                                }
                            }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Username")
                            .font(.body)
                            .fontWeight(.medium)
                        
                        TextField("Enter your Username", text: $username)
                            .textFieldStyle(CustomTextFieldStyle())
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .username)
                            .submitLabel(.next)
                            .onSubmit {
                                focusedField = nil
                            }
                            .onChange(of: username) { _, newValue in
                                // Фильтруем: только буквы, цифры и подчеркивание
                                let filtered = newValue.filter { $0.isLetter || $0.isNumber || $0 == "_" }
                                // Ограничиваем
                                let limited = String(filtered.prefix(Limits.maxNicknameLength))
                                if username != limited {
                                    username = limited
                                }
                            }
                    }
                    
                    HStack {
                        Text("Date of Birth")
                            .font(.body)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        DatePicker(
                            "",
                            selection: $birthDate,
                            in: ...Limits.maxBirthDate,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .padding()
                        .cornerRadius(12)
                        .accentColor(.newBlue)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.body)
                            .fontWeight(.medium)
                        
                        TextField("Enter your Email", text: $email)
                            .textFieldStyle(CustomTextFieldStyle())
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .foregroundStyle(.gray)
                            .disabled(true)
                    }
                }
                
                // Error message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.callout)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Register button
                AppButton(
                    text: "Register",
                    background: .newPink,
                    isLoading: $isLoading
                ) {
                    handleRegistration()
                }
                .disabled(!isFormValid)
                .opacity(isFormValid ? 1.0 : 0.5)
                .padding(.top, 10)
                
                HStack {
                    // Terms agreement
                    VStack(alignment: .leading) {
                        Text("By continuing, you agree to our")
                            .foregroundStyle(.primary)
                        
                        HStack(spacing: 4) {
                            Link("Terms of Service", destination: URL(string: URLs.termsUrl)!)
                                .foregroundStyle(.newBlue)
                            
                            Text("and")
                                .foregroundStyle(.primary)
                            
                            Link("Privacy Policy", destination: URL(string: URLs.privacyUrl)!)
                                .foregroundStyle(.newBlue)
                        }
                    }
                    .font(.callout)
                    .foregroundStyle(.gray)
                    
                    Spacer()
                }
                
                // Sign In link
                HStack(spacing: 4) {
                    Text("Not your account?")
                        .foregroundStyle(.secondary)
                    
                    Button {
                        // Handle sign in navigation
                        authViewModel.signOut()
                    } label: {
                        Text("Sign Out")
                            .foregroundStyle(.newBlue)
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                }
                .font(.callout)
                .padding(.bottom, 30)
            }
            .padding()
        }
        .scrollIndicators(.never)
        .onTapGesture {
            focusedField = nil
        }
        .photosPicker(isPresented: $showImagePicker, selection: $selectedItem, matching: .images)
        .sheet(isPresented: $showPresetsAvatar, content: {
            PresetAvatarsView(selectedAvatar: $avatarUrl)
        })
        .onChange(of: selectedItem) { _, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        avatarImage = image
                    }
                }
            }
        }
        .onAppear {
            if let draft = draft {
                firstName = draft.name ?? ""
                email = draft.email ?? ""
                avatarUrl = draft.avatarUrl
            }
            
            if email.isEmpty {
                DispatchQueue.main.async {
                    authViewModel.appState = .authenticating
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !username.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private func handleRegistration() {
        // Убираем фокус с полей
        focusedField = nil
        
        // Очищаем предыдущие ошибки
        errorMessage = nil
        
        // Валидация
        guard isFormValid else {
            errorMessage = "Please fill in all required fields"
            return
        }
        
        // Дополнительная валидация
        if username.count < 3 {
            errorMessage = "Username must be at least 3 characters"
            return
        }
        
        if firstName.count < 2 {
            errorMessage = "Name must be at least 2 characters"
            return
        }
        
        isLoading = true
        
        let trimmedFirstName = firstName.trimmingCharacters(in: .whitespaces)
        let trimmedUsername = username.trimmingCharacters(in: .whitespaces)
        
        Task {
            do {
                // Определяем URL аватара
                var finalAvatarUrl: String? = avatarUrl
                
                // Если есть avatarImage (фото с устройства), загружаем его на сервер
                if let avatarImage = avatarImage {
                    do {
                        finalAvatarUrl = try await authViewModel.userViewModel.uploadAvatar(avatarImage)
                    } catch {
                        await MainActor.run {
                            errorMessage = "Failed to upload avatar: \(error.localizedDescription)"
                            isLoading = false
                        }
                        return
                    }
                }
                
                // Отправляем данные на сервер
                await authViewModel.completeBootstrap(
                    name: trimmedFirstName,
                    username: trimmedUsername,
                    email: email.trimmingCharacters(in: .whitespaces),
                    avatarUrl: finalAvatarUrl,
                    birthDate: birthDate
                )
                
                await MainActor.run {
                    isLoading = false
                    // Проверяем, не произошла ли ошибка в authViewModel
                    if let error = authViewModel.error {
                        errorMessage = error
                    }
                }
            }
        }
    }
    
}

// Custom TextField Style
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.gray.opacity(0.08))
            .cornerRadius(12)
            .font(.body)
    }
}

#Preview {
    RegistrationView(draft: AppUserDraft(
        sub: "test-sub",
        email: "test@example.com",
        name: "John Doe",
        avatarUrl: nil
    ))
    .environmentObject(AuthViewModel.mock)
}
