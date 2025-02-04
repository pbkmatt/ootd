import SwiftUI
import _PhotosUI_SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

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
    @Environment(\.dismiss) private var dismiss  // ✅ Use dismiss() to close the view properly

    var body: some View {
        VStack(spacing: 16) {
            Text("Set Up Your Profile")
                .font(.custom("BebasNeue-Regular", size: 24))
                .padding(.top, 40)

            // Show email or phone if present (they're disabled here)
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

            // Profile Image Picker
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

            // Username
            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .padding(.horizontal)

            // Bio
            TextField("Bio (Optional, max 80 chars)", text: $bio)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.sentences)
                .padding(.horizontal)

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

    // MARK: - Create Account in Firestore
    private func submitProfile() {
        errorMessage = nil
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
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = error
                    self.isCreatingAccount = false
                } else {
                    // ✅ Dismiss ProfileSetupView properly after successful creation
                    dismiss()
                }
            }
        }
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
}
