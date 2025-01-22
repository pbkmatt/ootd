//
//  SettingsView.swift
//  OOTD
//
//  Created by Matt Imhof on 1/21/25.
//


import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var newfullName = ""
    @State private var newUsername = ""
    @State private var newBio = ""
    @State private var isPrivateProfile = false
    @State private var profilePicture: UIImage?
    @State private var showImagePicker = false
    @State private var isUpdating = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Settings")) {
                    TextField("Full Name", text: $newfullName)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    TextField("Username", text: $newUsername)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    TextField("Bio", text: $newBio)
                        .autocapitalization(.none)

                    Toggle("Private Profile", isOn: $isPrivateProfile)

                    Button(action: {
                        showImagePicker = true
                    }) {
                        HStack {
                            Text("Change Profile Picture")
                            Spacer()
                            Image(systemName: "photo")
                        }
                    }
                }

                Section {
                    Button("Save Changes") {
                        updateProfile()
                    }
                    .disabled(isUpdating || newUsername.isEmpty)
                }

                Section {
                    Button("Log Out") {
                        authViewModel.signOut()
                    }
                    .foregroundColor(.red)
                }

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $profilePicture)
            }
            .onAppear {
                loadProfileSettings()
            }
        }
    }

    private func loadProfileSettings() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore().collection("users").document(uid)

        db.getDocument { document, error in
            if let document = document, document.exists, let data = document.data() {
                newfullName = data["fullName"] as? String ?? ""
                newUsername = data["username"] as? String ?? ""
                newBio = data["bio"] as? String ?? ""
                isPrivateProfile = data["isPrivateProfile"] as? Bool ?? false
            } else {
                errorMessage = "Failed to load profile data."
            }
        }
    }


    private func updateProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isUpdating = true
        var updatedData: [String: Any] = [
            "fullName": newfullName,
            "username": newUsername,
            "bio": newBio,
            "isPrivateProfile": isPrivateProfile
        ]

        if let profileImage = profilePicture {
            uploadProfilePicture(image: profileImage) { url in
                if let url = url {
                    updatedData["profilePictureURL"] = url.absoluteString
                }
                saveProfileData(uid: uid, data: updatedData)
            }
        } else {
            saveProfileData(uid: uid, data: updatedData)
        }
    }

    private func uploadProfilePicture(image: UIImage, completion: @escaping (URL?) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            print("Error: Failed to convert image to data")
            completion(nil)
            return
        }

        let storageRef = Storage.storage().reference().child("profile_pictures/\(UUID().uuidString).jpg")
        storageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                print("Upload failed: \(error.localizedDescription)")
                completion(nil)
                return
            }

            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Error getting download URL: \(error.localizedDescription)")
                    completion(nil)
                } else {
                    completion(url)
                }
            }
        }
    }


    private func saveProfileData(uid: String, data: [String: Any]) {
        Firestore.firestore().collection("users").document(uid).updateData(data) { error in
            isUpdating = false
            if let error = error {
                errorMessage = "Failed to update profile: \(error.localizedDescription)"
            } else {
                errorMessage = nil
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            picker.dismiss(animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}
