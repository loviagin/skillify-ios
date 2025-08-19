//
//  EditProfileView.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 19.12.2023.
//

import SwiftUI
import Firebase
import FirebaseStorage
import Kingfisher

struct EditProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var first_name = ""
    @State private var last_name = ""
    @State private var bio = ""
    @State private var nickname = ""
    @State private var email = ""
    @State private var birthDate = Date()
    @State private var gender = "-"
    @State private var isImagePickerPresented = false
    @State private var showAvatarChooser = false
    @State private var showAvatarStandard = false
    @State private var selectedImage: UIImage?
    @State private var isLoading = false
    
    @State var isImageUploaded = false
    @State var isAvatarUploaded = false
    @State private var showNicknameAlert = false // Для отображения предупреждения
    @State private var showNicknameUAlert = false // Для отображения предупреждения
    @State private var showAlert: String? = nil
    @State var colorAvatar: Color = .brandBlue
    
    let genders = ["-", "Male", "Female", "Other"]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                HStack {
                    if let selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } else {
                        if UserHelper.avatars.contains(authViewModel.currentUser?.urlAvatar.split(separator: ":").first.map(String.init) ?? "") {
                            Image(authViewModel.currentUser!.urlAvatar.split(separator: ":").first.map(String.init) ?? "")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .padding(.top, 10)
                                .frame(width: 80, height: 80)
                                .padding(.vertical, 10)
                                .background(colorAvatar)
                                .clipShape(Circle())
                        } else if let urlString = authViewModel.currentUser?.urlAvatar, let url = URL(string: urlString) {
                            KFImage(url)
                                .resizable()
                                .placeholder {
                                    Image("user") // Плейсхолдер, отображаемый при загрузке
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 80, height: 80)
                                        .clipShape(Circle())
                                }
                                .clipShape(Circle()) // Делаем изображение круглым
                                .frame(width: 80, height: 80)
                                .padding(.vertical, 10)
                        } else {
                            Image("user") // Тот же плейсхолдер, если URL не существует
                                .resizable()
                                .frame(width: 80, height: 80)
                                .padding(.vertical, 10)
                        }
                    }
                    VStack(alignment: .leading) {
                        Text("Avatar image *")
                        Text("Choose your avatar")
                            .frame(width: 150, height: 20)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 5)
                            .background(.lGray)
                            .cornerRadius(15)
                            .onTapGesture {
                                showAvatarChooser = true
                            }
                            .confirmationDialog("Avatar type", isPresented: $showAvatarChooser, titleVisibility: .visible) {
                                Button("Standard avatar") {
                                    showAvatarStandard = true
                                }
                                Button("Your selfie") {
                                    isImagePickerPresented = true
                                }
                            } message: {
                                Text("Standard image or your selfie")
                            }
                            .sheet(isPresented: $showAvatarStandard) {
                                StandardAvatarView(isImageUploaded: $isAvatarUploaded, colorAvatar: $colorAvatar)
                                    .presentationDetents([.height(600), .large])
                            }
                    }
                    .padding(.leading, 20)
                    if UserHelper.isUserPro(authViewModel.currentUser?.proDate) {
                        Spacer()
                        
                        NavigationLink(destination: CustomizeProfileView()) {
                            Image(systemName: "paintbrush.pointed.fill")
                                .foregroundStyle(.brandBlue)
                        }
                    }
                }
                .padding(.bottom, 20)
                Text("First name *")
                TextField("Your First name", text: $first_name)
                    .textFieldStyle(.roundedBorder)
                    .padding(.bottom, 20)
                    .onReceive(first_name.publisher.collect()) {
                        let filtered = filterSpecialCharacters(from: String($0))
                        if filtered.count > 15 {
                            first_name = String(filtered.prefix(15))
                        } else {
                            first_name = filtered
                        }
                    }
                
                Text("Last name")
                TextField("Your Last name", text: $last_name)
                    .textFieldStyle(.roundedBorder)
                    .padding(.bottom, 20)
                    .onReceive(last_name.publisher.collect()) {
                        let filtered = filterSpecialCharacters(from: String($0))
                        if filtered.count > 15 {
                            last_name = String(filtered.prefix(15))
                        } else {
                            last_name = filtered
                        }
                    }
                Text("Short description")
                TextEditor(text: $bio)
                    .frame(height: 100)
                    .padding(5)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .onReceive(bio.publisher.collect()) {
                        let filtered = String($0)
                        if filtered.count > 75 {
                            bio = String(filtered.prefix(75))
                        } else {
                            bio = filtered
                        }
                    }
                
                Text("Nickname *")
                TextField("@nickname", text: $nickname)
                    .autocapitalization(.none)
                    .textFieldStyle(.roundedBorder)
                    .onReceive(nickname.publisher.collect()) {
                        let filtered = filterSpecialCharacters(from: String($0))
                        if filtered.count > 15 {
                            nickname = String(filtered.prefix(15))
                            showNicknameAlert = true
                        } else {
                            nickname = filtered
                        }
                    }
                    .alert(isPresented: $showNicknameAlert) {
                        Alert(title: Text("Invalid Character"),
                              message: Text("Only letters, numbers, hyphens, and underscores are allowed in nicknames."),
                              dismissButton: .default(Text("OK")))
                    }
                
                if showNicknameUAlert {
                    Text("This nickname already in use")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                DatePicker(
                    "Your birthday",
                    selection: $birthDate,
                    in: ...Date(), // Ограничиваем дату текущим днем и ранее
                    displayedComponents: .date // Показываем только компонент даты
                )
                .padding([.bottom, .top], 15)
                
                HStack {
                    Text("Select your gender")
                    Spacer()
                    Picker("Male", selection: $gender) {
                        ForEach(genders, id: \.self) { gender in
                            Text(gender).tag(gender)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                .padding(.bottom, 10)
                
                Text("Email")
                TextField("", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .disabled(true)
                
                Spacer()
                
                Button {
                    checkAgeAndSave()
                } label: {
                    if isLoading {
                        ProgressView()
                            .padding(.vertical, 15)
                            .frame(maxWidth: .infinity)
                            .background(.blue)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                    } else {
                        Text("Save")
                            .padding(.vertical, 15)
                            .frame(maxWidth: .infinity)
                            .background(.blue)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                    }
                }
                .padding(.top)
                Text("* - required field")
                    .font(.caption2)
            } // VStack main (after ScrollView main)
            
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .navigationTitle("Edit your profile")
            .navigationBarTitleDisplayMode(.inline)
            .onDisappear {
                checkAgeAndSave()
            }
            .onChange(of: selectedImage) { _, _ in
                if let selectedImage {
                    print("analyze")
                    analyzeImage(image: selectedImage)
                }
            }
            .onAppear {
                isLoading = false
                first_name = authViewModel.currentUser?.first_name ?? ""
                last_name = authViewModel.currentUser?.last_name ?? ""
                bio = authViewModel.currentUser?.bio ?? ""
                email = authViewModel.currentUser?.email ?? ""
                gender = authViewModel.currentUser?.sex.isEmpty ?? true ? "-" : authViewModel.currentUser?.sex ?? "Male"
                if UserHelper.avatars.contains(authViewModel.currentUser?.urlAvatar.split(separator: ":").first.map(String.init) ?? "") {
                    if let colorString = authViewModel.currentUser?.urlAvatar.split(separator: ":").last.map(String.init) {
                        self.colorAvatar = Color.fromRGBAString(colorString) ?? Color.blue.opacity(0.4)
                    } else {
                        self.colorAvatar = Color.blue.opacity(0.4)
                    }
                }
                if let nk = authViewModel.currentUser?.nickname {
                    if nk.isEmpty {
                        let v = UserHelper.generateNickname()
                        DispatchQueue.main.async {
                            nickname = v
                        }
                    } else {
                        nickname = nk
                    }
                }
                nickname = authViewModel.currentUser?.nickname ?? ""
                birthDate = authViewModel.currentUser?.birthday ?? Date()
            }
            .sheet(isPresented: $isImagePickerPresented) {
                ImagePicker(selectedImage: $selectedImage, isImageUploaded: $isImageUploaded, allowsEditing: true)
                    .ignoresSafeArea()
            }
        }
        
        .alert(isPresented: .constant(showAlert != nil)) {
            Alert(
                title: Text(showAlert!),
                message: Text(""),
                dismissButton: .default(Text("OK"), action: {
                    showAlert = nil // Сбросить showAlert после закрытия алерта
                })
            )
        }
    }
    
    func analyzeImage(image: UIImage) {
        let apiKey = "AIzaSyBSJ8O0pLR9Ve7S6zX2zA0kqb4wi2LMY6Q"
        let url = URL(string: "https://vision.googleapis.com/v1/images:annotate?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let base64Image = image.jpegData(compressionQuality: 1.0)?.base64EncodedString() ?? ""
        let requestJson: [String: Any] = [
            "requests": [
                [
                    "image": ["content": base64Image],
                    "features": [["type": "SAFE_SEARCH_DETECTION"]]
                ]
            ]
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: requestJson, options: []) else {
            return
        }
        request.httpBody = httpBody
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error making request: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
            
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let responses = jsonResponse["responses"] as? [[String: Any]],
                       let safeSearchAnnotation = responses.first?["safeSearchAnnotation"] as? [String: Any] {
                        DispatchQueue.main.async {
                            self.handleSafeSearchAnnotation(safeSearchAnnotation)
                        }
                    } else {
                        //                                print("SafeSearch annotation not found in the response")
                        //                                DispatchQueue.main.async {
                        ////                                    self.showAlert = "Error analyzing image: SafeSearch annotation not found"
                        //                                }
                    }
                } else {
                    print("Failed to parse JSON response")
                    //                            DispatchQueue.main.async {
                    ////                                self.showAlert = "Error analyzing image: Failed to parse JSON response"
                    //                            }
                }
            } catch {
                print("Error parsing JSON: \(error.localizedDescription)")
                //                        DispatchQueue.main.async {
                ////                            self.showAlert = "Error analyzing image: \(error.localizedDescription)"
                //                        }
            }
        }.resume()
    }
    
    func handleSafeSearchAnnotation(_ annotation: [String: Any]) {
        let adult = annotation["adult"] as? String ?? "UNKNOWN"
        let racy = annotation["racy"] as? String ?? "UNKNOWN"
        let violence = annotation["violence"] as? String ?? "UNKNOWN"
        
        if adult == "LIKELY" || adult == "VERY_LIKELY" || racy == "LIKELY" || racy == "VERY_LIKELY" || violence == "LIKELY" || violence == "VERY_LIKELY" {
            self.selectedImage = nil
            self.isImageUploaded = false
            self.showAlert = "The selected image contains inappropriate content."
        } else {
            self.isImageUploaded = true
        }
    }
    
    func filterSpecialCharacters(from string: String) -> String {
        let allowedCharacters = CharacterSet.letters.union(.decimalDigits).union(CharacterSet(charactersIn: "-_"))
        return string.filter { String($0).rangeOfCharacter(from: allowedCharacters) != nil }
    }
    
    
    func uploadImage() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        if isImageUploaded {
            guard let imageData = selectedImage?.jpegData(compressionQuality: 0.5) else { return }
            
            let storageRef = Storage.storage().reference().child("iosUsers/\(uid)/avatar.jpg")
            storageRef.putData(imageData, metadata: nil) { metadata, error in
                guard metadata != nil else {
                    // Обработка ошибки загрузки
                    return
                }
                
                storageRef.downloadURL { url, error in
                    guard let downloadURL = url else {
                        // Обработка ошибки получения URL
                        return
                    }
                    
                    // Сохранение URL в Firestore
                    saveDataWithAvatar(uid: uid, avatar: downloadURL.absoluteString)
                }
            }
        } else if isAvatarUploaded {
            saveDataWithAvatar(uid: uid, avatar: authViewModel.currentUser!.urlAvatar)
        } else if authViewModel.currentUser!.urlAvatar != "" {
            let db = Firestore.firestore()
            db.collection("users").document(uid).updateData(["first_name": first_name,
                                                             "last_name": last_name,
                                                             "bio": bio,
                                                             "sex": gender,
                                                             "birthday": birthDate,
                                                             "nickname": nickname]) { error in
                if let error = error {
                    // Обработка ошибки обновления Firestore
                    print("Error updating document: \(error)")
                } else {
                    authViewModel.currentUser?.first_name = first_name
                    authViewModel.currentUser?.last_name = last_name
                    authViewModel.currentUser?.bio = bio
                    authViewModel.currentUser?.sex = gender
                    authViewModel.currentUser?.nickname = nickname
                    authViewModel.currentUser?.birthday = birthDate
                    print("Document successfully updated")
                }
            }
        }
    }
    
    private func saveDataWithAvatar(uid: String, avatar: String) {
        let db = Firestore.firestore()
        let ava = "\(avatar):\((UIColor(colorAvatar).cgColor.components?.map { "\($0)" }.joined(separator: ","))!)"
        print(ava)
        db.collection("users").document(uid).updateData(["urlAvatar": ava,
                                                         "first_name": first_name,
                                                         "last_name": last_name,
                                                         "bio": bio,
                                                         "sex": gender,
                                                         "birthday": birthDate,
                                                         "nickname": nickname,]) { error in
            if let error = error {
                // Обработка ошибки обновления Firestore
                print("Error updating document: \(error)")
            } else {
                authViewModel.currentUser?.first_name = first_name
                authViewModel.currentUser?.last_name = last_name
                authViewModel.currentUser?.bio = bio
                authViewModel.currentUser?.sex = gender
                authViewModel.currentUser?.birthday = birthDate
                authViewModel.currentUser?.nickname = nickname
                authViewModel.currentUser?.urlAvatar = ava
                print("Document successfully updated")
            }
        }
    }
    
    func checkAgeAndSave() {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: Date())
        let age = ageComponents.year ?? 0
        if age < 12 {
            DispatchQueue.main.async {
                showAlert = "You must be 12 years old or older"
            }
        } else if first_name.isEmpty {
            DispatchQueue.main.async {
                showAlert = "Please enter your Name"
            }
        } else if !isImageUploaded && authViewModel.currentUser!.urlAvatar == "" {
            DispatchQueue.main.async {
                showAlert = "Please upload your avatar"
            }
        } else {
            isLoading = true
            UserDefaults.standard.setValue(first_name, forKey: "nameUser")
            authViewModel.isNicknameUnique(nickname) { isUnique in
                withAnimation {
                    if isUnique {
                        DispatchQueue.main.async {
                            showNicknameUAlert = false
                        }
                        isLoading = false
                        uploadImage()
                        dismiss()
                        if authViewModel.userState == .profileEditRequired {
                            authViewModel.userState = .loggedIn
                        }
                    } else {
                        DispatchQueue.main.async {
                            showNicknameUAlert = true
                            isLoading = false
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    EditProfileView()
        .environmentObject(AuthViewModel.mock)
}
