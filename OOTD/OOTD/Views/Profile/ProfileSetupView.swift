import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import PhotosUI

struct ProfileSetupView: View {
    @State private var fullName: String = ""
    @State private var username: String = ""
    @State private var instagramHandle: String = ""
    @State private var profileImage: UIImage? = nil
    @State private var isCropping = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil

    @State private var errorMessage: String?
    @State private var isCreatingAccount = false

    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 16) {
            Text("Set Up Your Profile")
                .font(Font.custom("BebasNeue-Regular", size: 24))
                .padding(.top, 40)

            // Display uneditable email or phone number
            if !authViewModel.currentEmail.isEmpty {
                TextField("E-Mail", text: .constant(authViewModel.currentEmail))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(true)
                    .padding()
                    .background(Color.gray.opacity(0.3))
            }
            if !authViewModel.currentPhone.isEmpty {
                TextField("Phone Number", text: .constant(authViewModel.currentPhone))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(true)
                    .padding()
                    .background(Color.gray.opacity(0.3))
            }

            // Profile Picture Picker
            PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                if let profileImage = profileImage {
                    Image(uiImage: profileImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                        .shadow(radius: 5)
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 120, height: 120)
                        .overlay(Text("Choose Photo").foregroundColor(.white))
                }
            }
            .onChange(of: selectedPhotoItem) { _ in
                loadProfileImage()
            }

            // Full Name Input
            TextField("Full Name", text: $fullName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.words)
                .padding(.horizontal)

            // Username Input
            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .padding(.horizontal)

            // Instagram Handle Input (Optional)
            TextField("Instagram Handle (Optional)", text: $instagramHandle)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .padding(.horizontal)

            // Create Account Button
            Button("Create Account") {
                validateAndSubmit()
            }
            .disabled(isCreatingAccount)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(isCreatingAccount ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.horizontal)

            Spacer()
        }
        .background(Color(.systemBackground).ignoresSafeArea())
    }

    private func validateAndSubmit() {
        errorMessage = nil

        guard !fullName.isEmpty, !username.isEmpty, profileImage != nil else {
            errorMessage = "All required fields must be filled out."
            return
        }

        isCreatingAccount = true
        checkUsernameAvailability(username) { isAvailable in
            if isAvailable {
                uploadProfileImage { imageURL in
                    if let imageURL = imageURL {
                        saveUserData(profilePictureURL: imageURL)
                    } else {
                        errorMessage = "Error uploading profile picture."
                        isCreatingAccount = false
                    }
                }
            } else {
                errorMessage = "Username is already taken."
                isCreatingAccount = false
            }
        }
    }

    // MARK: - Save User Data in Firestore
    private func saveUserData(profilePictureURL: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let userData: [String: Any] = [
            "fullName": fullName,
            "username": username.lowercased(),
            "instagramHandle": instagramHandle,
            "profilePictureURL": profilePictureURL,
            "email": authViewModel.currentEmail,
            "phone": authViewModel.currentPhone,
            "followersCount": 0,
            "followingCount": 0,
            "createdAt": FieldValue.serverTimestamp(),
            "isPrivateProfile": false
        ]

        Firestore.firestore().collection("users").document(uid).setData(userData) { error in
            if let error = error {
                self.errorMessage = "Error saving profile data: \(error.localizedDescription)"
                self.isCreatingAccount = false
            } else {
                DispatchQueue.main.async {
                    authViewModel.completeProfileSetup(fullName: fullName, username: username, profilePictureURL: profilePictureURL) { error in
                        if let error = error {
                            self.errorMessage = error
                        } else {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Upload Profile Picture to Firebase Storage
    private func uploadProfileImage(completion: @escaping (String?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid, let profileImage = profileImage else {
            completion(nil)
            return
        }

        let storageRef = Storage.storage().reference().child("profile_pictures/\(uid).jpg")
        guard let imageData = profileImage.jpegData(compressionQuality: 0.7) else {
            completion(nil)
            return
        }

        storageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                print("Error uploading profile picture: \(error.localizedDescription)")
                completion(nil)
                return
            }

            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Error retrieving image URL: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                completion(url?.absoluteString)
            }
        }
    }

    // MARK: - Check Username Availability
    private func checkUsernameAvailability(_ username: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        db.collection("users").whereField("username", isEqualTo: username).getDocuments { snapshot, error in
            if let error = error {
                self.errorMessage = "Error checking username: \(error.localizedDescription)"
                completion(false)
            } else {
                completion(snapshot?.documents.isEmpty ?? true)
            }
        }
    }

    // MARK: - Load Profile Image from PhotosPicker
    private func loadProfileImage() {
        guard let selectedPhotoItem else { return }

        selectedPhotoItem.loadTransferable(type: Data.self) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let imageData?):
                    if let image = UIImage(data: imageData) {
                        self.profileImage = image
                        self.isCropping = true
                    }
                case .failure(let error):
                    self.errorMessage = "Error loading image: \(error.localizedDescription)"
                default:
                    break
                }
            }
        }
    }
}
