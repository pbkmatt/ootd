import SwiftUI
import PhotosUI

struct ProfileSetupView: View {
    let password: String

    @State private var fullName: String = ""
    @State private var username: String = ""
    @State private var bio: String = ""
    @State private var instagramHandle: String = ""
    @State private var profileImage: UIImage? = nil
    @State private var selectedPhotoItem: PhotosPickerItem? = nil

    @State private var errorMessage: String?
    @State private var isCreatingAccount = false

    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 16) {
            Text("Set Up Your Profile")
                .font(.custom("BebasNeue-Regular", size: 24))
                .padding(.top, 40)

            // Show email or phone if present
            if !authViewModel.currentEmail.isEmpty {
                TextField("", text: .constant(authViewModel.currentEmail))
                    .disabled(true)
                    .padding()
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(8)
                    .padding(.horizontal)
            }
            if !authViewModel.currentPhone.isEmpty {
                TextField("", text: .constant(authViewModel.currentPhone))
                    .disabled(true)
                    .padding()
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(8)
                    .padding(.horizontal)
            }

            // Choose Profile Picture
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                if let image = profileImage {
                    Image(uiImage: image)
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

            // Full Name
            TextField("Full Name", text: $fullName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.words)
                .padding(.horizontal)
                .onChange(of: fullName) { newValue in
                    fullName = validateFullName(newValue)
                }

            // Username
            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .padding(.horizontal)
                .onChange(of: username) { newValue in
                    username = validateUsername(newValue)
                }

            // Bio
            TextField("Bio (Optional, max 80 chars)", text: $bio)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.sentences)
                .padding(.horizontal)
                .onChange(of: bio) { newValue in
                    bio = validateBio(newValue)
                }

            // Instagram Handle
            TextField("Instagram Handle (Optional)", text: $instagramHandle)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .padding(.horizontal)

            // "Create Account"
            Button("Create Account") {
                submitProfile()
            }
            .disabled(isCreatingAccount)
            .frame(maxWidth: .infinity)
            .background(isCreatingAccount ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.horizontal)

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.custom("OpenSans", size: 14))
                    .padding(.top, 4)
            }

            Spacer()
        }
        .background(Color(.systemBackground).ignoresSafeArea())
    }

    // MARK: - Load Photo
    private func loadProfileImage() {
        guard let selectedPhotoItem else { return }
        selectedPhotoItem.loadTransferable(type: Data.self) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data?):
                    if let uiImage = UIImage(data: data) {
                        profileImage = uiImage
                    }
                case .failure(let error):
                    errorMessage = "Error loading image: \(error.localizedDescription)"
                default:
                    break
                }
            }
        }
    }

    // MARK: - Create Account in Firestore
    private func submitProfile() {
        errorMessage = nil
        // Check required fields
        guard !fullName.isEmpty,
              !username.isEmpty,
              profileImage != nil else {
            errorMessage = "All required fields must be filled."
            return
        }

        isCreatingAccount = true
        authViewModel.createUserAfterProfileSetup(
            fullName: fullName,
            username: username,
            bio: bio,
            instagramHandle: instagramHandle,
            profileImage: profileImage,
            password: password
        ) { error in
            if let error = error {
                errorMessage = error
                isCreatingAccount = false
            } else {
                // On success, isAuthenticated is set in the viewModel
            }
        }
    }

    // MARK: - Validation
    private func validateFullName(_ name: String) -> String {
        let allowed = CharacterSet.letters
            .union(.decimalDigits)
            .union(CharacterSet(charactersIn: " -'"))
        let filtered = name.unicodeScalars.filter { allowed.contains($0) }
        return String(filtered.prefix(40))
    }

    private func validateUsername(_ name: String) -> String {
        let allowed = CharacterSet.letters.union(.decimalDigits)
        let filtered = name.unicodeScalars.filter { allowed.contains($0) }
        return String(filtered.prefix(20))
    }

    private func validateBio(_ text: String) -> String {
        return String(text.prefix(80))
    }
}
