import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct ProfileSetupView: View {
    @State private var fullName = ""
    @State private var bio = ""
    @State private var isPrivate = false
    @State private var instagramHandle = ""
    @State private var profileImage: UIImage? = nil
    @State private var croppedImage: UIImage? = nil
    @State private var showImagePicker = false
    @State private var showCropView = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Set Up Your Profile")
                        .font(Font.custom("BebasNeue-Regular", size: 28))
                        .padding(.top, 20)

                    formFields

                    profilePictureSection

                    saveButton

                    if isLoading {
                        ProgressView()
                    }

                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(Font.custom("OpenSans", size: 14))
                            .padding(.top)
                    }
                }
                .padding()
            }
            .background(Color(.systemBackground).ignoresSafeArea())
            .navigationBarTitle("Profile Setup", displayMode: .inline)
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $profileImage, showCropView: $showCropView)
            }
            .sheet(isPresented: $showCropView) {
                if let profileImage = profileImage {
                    CropView(image: profileImage, croppedImage: $croppedImage)
                }
            }
        }
    }

    private var formFields: some View {
        Group {
            TextField("Full Name", text: $fullName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            TextField("Bio (Max 40 characters)", text: $bio)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .onChange(of: bio) { newValue in
                    bio = String(newValue.prefix(40))
                }

            TextField("Instagram Handle", text: $instagramHandle)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .onChange(of: instagramHandle) { newValue in
                    instagramHandle = String(newValue.prefix(36))
                }

            Toggle("Private Profile", isOn: $isPrivate)
                .padding(.horizontal)
        }
    }

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

    private var saveButton: some View {
        Button(action: saveUserProfile) {
            Text("Save Profile")
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.blue)
                .foregroundColor(.white)
                .font(Font.custom("BebasNeue-Regular", size: 18))
                .cornerRadius(10)
                .padding(.horizontal)
        }
        .disabled(isLoading || croppedImage == nil || fullName.isEmpty)
    }

    private func saveUserProfile() {
        guard let uid = Auth.auth().currentUser?.uid, let croppedImage = croppedImage else {
            errorMessage = "Please complete all required fields."
            return
        }

        isLoading = true
        uploadProfileImage(image: croppedImage) { url in
            guard let profilePictureURL = url else {
                errorMessage = "Failed to upload profile picture."
                isLoading = false
                return
            }

            let userData: [String: Any] = [
                "uid": uid,
                "fullName": fullName,
                "bio": bio,
                "instagramHandle": instagramHandle,
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
    }

    private func uploadProfileImage(image: UIImage, completion: @escaping (String?) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            completion(nil)
            return
        }

        let storageRef = Storage.storage().reference().child("profile_pictures/\(UUID().uuidString).jpg")
        storageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                completion(nil)
            } else {
                storageRef.downloadURL { url, _ in
                    completion(url?.absoluteString)
                }
            }
        }
    }
}
