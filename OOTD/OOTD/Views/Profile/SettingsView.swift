import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var newFullName = ""
    @State private var newUsername = ""
    @State private var newBio = ""
    @State private var instagramHandle = ""
    @State private var isPrivateProfile = false
    @State private var profileImage: UIImage?
    @State private var croppedImage: UIImage?
    @State private var showImagePicker = false
    @State private var showCropView = false
    @State private var isUpdating = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Settings")
                        .font(Font.custom("BebasNeue-Regular", size: 28))
                        .padding(.top, 20)

                    profilePictureSection

                    Form {
                        // Profile Settings Section
                        Section(header: Text("Profile Settings")) {
                            TextField("Full Name", text: $newFullName)
                                .autocapitalization(.words)
                                .disableAutocorrection(true)

                            TextField("Username", text: $newUsername)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)

                            TextField("Bio", text: $newBio)
                                .autocapitalization(.sentences)

                            TextField("Instagram Handle", text: $instagramHandle)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .onChange(of: instagramHandle) { newValue in
                                    if newValue.count > 36 {
                                        instagramHandle = String(newValue.prefix(36))
                                    }
                                }

                            Toggle("Private Profile", isOn: $isPrivateProfile)
                        }

                        // Save Changes Section
                        Section {
                            Button(action: updateProfile) {
                                Text("Save Changes")
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .font(Font.custom("BebasNeue-Regular", size: 18))
                                    .cornerRadius(10)
                            }
                            .disabled(isUpdating || newUsername.isEmpty)
                        }

                        // Logout Section
                        Section {
                            Button(action: {
                                authViewModel.signOut()
                            }) {
                                Text("Log Out")
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.red)
                                    .foregroundColor(.white)
                                    .font(Font.custom("BebasNeue-Regular", size: 18))
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .frame(height: 500) // Adjust height as needed

                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(Font.custom("OpenSans", size: 14))
                            .padding()
                    }
                }
                .padding()
            }
            .background(Color(.systemBackground).ignoresSafeArea())
            .navigationBarTitle("Settings", displayMode: .inline)
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $profileImage, showCropView: $showCropView)
            }
            .sheet(isPresented: $showCropView) {
                if let profileImage = profileImage {
                    CropView(image: profileImage, croppedImage: $croppedImage)
                }
            }
            .onAppear {
                loadProfileSettings()
            }
        }
    }

    // MARK: - Profile Picture Section
    private var profilePictureSection: some View {
        VStack {
            if let croppedImage = croppedImage {
                Image(uiImage: croppedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                    .padding()
            } else {
                Circle()
                    .fill(Color.gray)
                    .frame(width: 120, height: 120)
                    .overlay(Text("Tap to select image").foregroundColor(.white))
                    .onTapGesture {
                        showImagePicker = true
                    }
            }
        }
    }

    // MARK: - Load Profile Settings
    private func loadProfileSettings() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore().collection("users").document(uid)

        db.getDocument { document, error in
            if let document = document, document.exists, let data = document.data() {
                newFullName = data["fullName"] as? String ?? ""
                newUsername = data["username"] as? String ?? ""
                newBio = data["bio"] as? String ?? ""
                instagramHandle = data["instagramHandle"] as? String ?? ""
                isPrivateProfile = data["isPrivateProfile"] as? Bool ?? false

                if let profilePictureURL = data["profilePictureURL"] as? String,
                   let url = URL(string: profilePictureURL) {
                    loadImage(from: url)
                }
            } else {
                errorMessage = "Failed to load profile data."
            }
        }
    }

    // MARK: - Load Image from URL
    private func loadImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    profileImage = image
                    croppedImage = image
                }
            } else {
                errorMessage = "Failed to load profile picture."
            }
        }.resume()
    }

    // MARK: - Update Profile
    private func updateProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isUpdating = true
        var updatedData: [String: Any] = [
            "fullName": newFullName,
            "username": newUsername,
            "bio": newBio,
            "instagramHandle": instagramHandle,
            "isPrivateProfile": isPrivateProfile
        ]

        if let croppedImage = croppedImage {
            uploadProfilePicture(image: croppedImage) { url in
                if let url = url {
                    updatedData["profilePictureURL"] = url.absoluteString
                }
                saveProfileData(uid: uid, data: updatedData)
            }
        } else {
            saveProfileData(uid: uid, data: updatedData)
        }
    }

    // MARK: - Upload Profile Picture
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

    // MARK: - Save Profile Data
    private func saveProfileData(uid: String, data: [String: Any]) {
        Firestore.firestore().collection("users").document(uid).updateData(data) { error in
            isUpdating = false
            if let error = error {
                errorMessage = "Failed to update profile: \(error.localizedDescription)"
            } else {
                errorMessage = nil
                // Fetch updated user details to refresh local state
                authViewModel.fetchUserDetails(for: uid) { _ in
                    // Handle any additional logic if needed after updating local state
                }
            }
        }
    }
}
