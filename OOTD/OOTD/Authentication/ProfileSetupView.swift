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
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Text("Set Up Your Profile")
                .font(.custom("BebasNeue-Regular", size: 30))
                .foregroundColor(.primary)
                .padding(.top, 40)

            // MARK: - Email or Phone Display (Disabled)
            if !authViewModel.currentEmail.isEmpty {
                TextField("", text: .constant(authViewModel.currentEmail))
                    .font(.custom("OpenSans", size: 16))
                    .disabled(true)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                    .padding(.horizontal, 40)
            }
            if !authViewModel.currentPhone.isEmpty {
                TextField("", text: .constant(authViewModel.currentPhone))
                    .font(.custom("OpenSans", size: 16))
                    .disabled(true)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                    .padding(.horizontal, 40)
            }

            // MARK: - Profile Image Picker
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                ZStack {
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
                            .overlay(
                                Text("Choose Photo")
                                    .font(.custom("OpenSans", size: 14))
                                    .foregroundColor(.white)
                            )
                    }
                }
            }
            .onChange(of: selectedPhotoItem) { _ in
                loadProfileImage()
            }

            // MARK: - Full Name
            TextField("Full Name", text: $fullName)
                .font(.custom("OpenSans", size: 16))
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .autocapitalization(.words)
                .padding(.horizontal, 40)

            // MARK: - Username
            TextField("Username", text: $username)
                .font(.custom("OpenSans", size: 16))
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .autocapitalization(.none)
                .padding(.horizontal, 40)

            // MARK: - Bio
            TextField("Bio (Optional, max 80 chars)", text: $bio)
                .font(.custom("OpenSans", size: 16))
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .autocapitalization(.sentences)
                .padding(.horizontal, 40)

            // MARK: - Instagram Handle
            TextField("Instagram Handle (Optional)", text: $instagramHandle)
                .font(.custom("OpenSans", size: 16))
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .autocapitalization(.none)
                .padding(.horizontal, 40)

            // MARK: - Create Account Button
            Button("Create Account") {
                submitProfile()
            }
            .font(.custom("BebasNeue-Regular", size: 18))
            .foregroundColor(.white)
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .background(isCreatingAccount ? Color.gray : Color.blue)
            .cornerRadius(12)
            .padding(.horizontal, 40)
            .disabled(isCreatingAccount)

            // MARK: - Error Message
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.custom("OpenSans", size: 14))
                    .foregroundColor(.red)
                    .padding(.horizontal, 40)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .background(Color(.systemBackground).ignoresSafeArea())
    }

    // MARK: - Create Account
    private func submitProfile() {
        errorMessage = nil
        guard !fullName.isEmpty, !username.isEmpty, profileImage != nil else {
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
