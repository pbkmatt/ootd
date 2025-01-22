import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import PhotosUI

struct ProfileSetupView: View {
    @State private var username = ""
    @State private var bio = ""
    @State private var isPrivate = false
    @State private var profileImage: UIImage? = nil
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showImagePicker = false
    @State private var selectedItem: PhotosPickerItem? = nil
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            Text("Set Up Your Profile")
                .font(.largeTitle)
                .bold()
                .padding()

            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            TextField("Bio", text: $bio)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Toggle("Private Profile", isOn: $isPrivate)
                .padding()

            PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                if let profileImage = profileImage {
                    Image(uiImage: profileImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                } else {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .onChange(of: selectedItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        profileImage = uiImage
                    }
                }
            }

            Button("Save Profile") {
                saveUserProfile()
            }
            .frame(width: 200, height: 50)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding()

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }

            if isLoading {
                ProgressView()
            }
        }
        .padding()
    }

    private func saveUserProfile() {
        guard let uid = Auth.auth().currentUser?.uid, !username.isEmpty else {
            errorMessage = "Please enter a valid username."
            return
        }
        
        isLoading = true
        var profilePictureURL = ""

        if let profileImage = profileImage {
            uploadProfileImage(image: profileImage) { url in
                profilePictureURL = url ?? ""
                saveData(uid: uid, profilePictureURL: profilePictureURL)
            }
        } else {
            saveData(uid: uid, profilePictureURL: profilePictureURL)
        }
    }

    private func saveData(uid: String, profilePictureURL: String) {
        let userData: [String: Any] = [
            "uid": uid,
            "username": username,
            "bio": bio,
            "profilePictureURL": profilePictureURL,
            "isPrivate": isPrivate
        ]

        Firestore.firestore().collection("users").document(uid).setData(userData) { error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    errorMessage = "Error saving profile: \(error.localizedDescription)"
                } else {
                    authViewModel.isAuthenticated = true
                }
            }
        }
    }

    private func uploadProfileImage(image: UIImage, completion: @escaping (String?) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            completion(nil)
            return
        }

        let storageRef = Storage.storage().reference().child("profilePictures/\(UUID().uuidString).jpg")
        storageRef.putData(imageData, metadata: nil) { _, error in
            if error == nil {
                storageRef.downloadURL { url, _ in
                    completion(url?.absoluteString)
                }
            } else {
                completion(nil)
            }
        }
    }
}
