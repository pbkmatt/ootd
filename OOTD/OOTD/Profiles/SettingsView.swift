import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import PhotosUI

// An enum for the user’s post filter choice
enum ProfilePostFilter: String, CaseIterable {
    case today       = "today"
    case last7days   = "last7days"
    case all         = "all"
}

struct SettingsView: View {
    @State private var fullName: String = ""
    @State private var username: String = ""
    @State private var instagramHandle: String = ""
    @State private var profileImage: UIImage? = nil
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var errorMessage: String?
    @State private var isUpdating = false

    // New: store the user’s selected filter
    @State private var selectedFilter: ProfilePostFilter = .all

    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 16) {
            Text("Edit Profile")
                .font(.custom("BebasNeue-Regular", size: 24))
                .padding(.top, 40)

            // MARK: - Profile Picture Picker
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
                        .overlay(Text("Change Photo").foregroundColor(.white))
                }
            }
            .onChange(of: selectedPhotoItem) { _ in
                loadProfileImage()
            }

            // MARK: - Full Name Input
            TextField("Full Name", text: $fullName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.words)
                .padding(.horizontal)
                .onChange(of: fullName) { newValue in
                    if newValue.count > 40 {
                        fullName = String(newValue.prefix(40))
                    }
                }

            // MARK: - Username Input
            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .padding(.horizontal)
                .onChange(of: username) { newValue in
                    let filtered = newValue.lowercased().filter { $0.isLetter || $0.isNumber }
                    username = String(filtered.prefix(20))
                }

            // MARK: - Instagram Handle
            TextField("Instagram Handle (Optional)", text: $instagramHandle)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .padding(.horizontal)
                .onChange(of: instagramHandle) { newValue in
                    let filtered = newValue.filter { $0.isLetter || $0.isNumber || $0 == "." || $0 == "_" }
                    instagramHandle = String(filtered.prefix(36))
                }

            // MARK: - Post Filter Picker
            Text("Which posts to display on your profile?")
                .font(.subheadline)
                .foregroundColor(.gray)

            Picker("Profile Posts", selection: $selectedFilter) {
                Text("Only Today").tag(ProfilePostFilter.today)
                Text("Last 7 Days").tag(ProfilePostFilter.last7days)
                Text("All Time").tag(ProfilePostFilter.all)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            // MARK: - Error Message
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.custom("OpenSans", size: 14))
                    .padding(.top)
            }

            // MARK: - Save Button
            Button("Save Changes") {
                validateAndSubmit()
            }
            .disabled(isUpdating)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(isUpdating ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .font(.custom("BebasNeue-Regular", size: 18))
            .cornerRadius(10)
            .padding(.horizontal)

            Spacer()
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .onAppear {
            loadUserProfile()
        }
    }

    // MARK: - Load Selected Photo
    private func loadProfileImage() {
        guard let selectedPhotoItem else { return }

        selectedPhotoItem.loadTransferable(type: Data.self) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let imageData?):
                    if let image = UIImage(data: imageData) {
                        self.profileImage = image
                    }
                case .failure(let error):
                    self.errorMessage = "Error loading image: \(error.localizedDescription)"
                default:
                    break
                }
            }
        }
    }

    // MARK: - Validate Input, Check Username, then Save
    private func validateAndSubmit() {
        errorMessage = nil
        guard !fullName.isEmpty, !username.isEmpty else {
            errorMessage = "All required fields must be filled out."
            return
        }
        isUpdating = true
        checkUsernameAvailability(username) { isAvailable in
            if isAvailable {
                saveProfileData()
            } else {
                errorMessage = "Username is already taken."
                isUpdating = false
            }
        }
    }

    // MARK: - Check Username
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

    // MARK: - Save to Firestore
    private func saveProfileData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        var userData: [String: Any] = [
            "fullName": self.fullName,
            "username": self.username,
            "instagramHandle": self.instagramHandle,
            "profilePostFilter": self.selectedFilter.rawValue // store the filter
        ]

        // If profileImage changed, upload
        if let profileImage = profileImage {
            let storageRef = FirebaseManager.shared.storage
                .reference().child("profile_pictures/\(uid).jpg")
            guard let imageData = profileImage.jpegData(compressionQuality: 0.7) else {
                self.isUpdating = false
                return
            }
            storageRef.putData(imageData, metadata: nil) { _, error in
                if let error = error {
                    self.errorMessage = "Error uploading profile picture: \(error.localizedDescription)"
                    self.isUpdating = false
                    return
                }
                storageRef.downloadURL { url, error in
                    if let error = error {
                        self.errorMessage = "Error retrieving image URL: \(error.localizedDescription)"
                        self.isUpdating = false
                        return
                    }
                    guard let imageUrl = url?.absoluteString else { return }
                    userData["profilePictureURL"] = imageUrl

                    db.collection("users").document(uid).updateData(userData) { error in
                        if let error = error {
                            self.errorMessage = "Error saving profile data: \(error.localizedDescription)"
                        }
                        self.isUpdating = false
                        // close view
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        } else {
            // No new profile picture
            db.collection("users").document(uid).updateData(userData) { error in
                if let error = error {
                    self.errorMessage = "Error saving profile data: \(error.localizedDescription)"
                }
                self.isUpdating = false
                // close
                self.presentationMode.wrappedValue.dismiss()
            }
        }
    }

    // MARK: - Load Existing User Profile
    private func loadUserProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { document, error in
            if let doc = document, doc.exists {
                let data = doc.data() ?? [:]
                self.fullName = data["fullName"] as? String ?? ""
                self.username = data["username"] as? String ?? ""
                self.instagramHandle = data["instagramHandle"] as? String ?? ""

                // If no filter stored yet, default to "all"
                if let rawFilter = data["profilePostFilter"] as? String,
                   let f = ProfilePostFilter(rawValue: rawFilter) {
                    self.selectedFilter = f
                } else {
                    self.selectedFilter = .all
                }
            } else {
                self.errorMessage = "Error loading profile."
            }
        }
    }
}
