import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import PhotosUI

struct ProfileSetupView: View {
    let password: String // Passed from SignUpView

    @State private var fullName: String = ""
    @State private var username: String = ""
    @State private var instagramHandle: String = ""
    @State private var profileImage: UIImage? = nil
    @State private var selectedPhotoItem: PhotosPickerItem? = nil

    @State private var errorMessage: String?
    @State private var isCreatingAccount = false
    @State private var navigateToTour = false

    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 16) {
            Text("Set Up Your Profile")
                .font(Font.custom("BebasNeue-Regular", size: 24))
                .padding(.top, 40)

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

            TextField("Full Name", text: $fullName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.words)
                .padding(.horizontal)

            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .padding(.horizontal)

            TextField("Instagram Handle (Optional)", text: $instagramHandle)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .padding(.horizontal)

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
        .fullScreenCover(isPresented: $navigateToTour, onDismiss: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                authViewModel.isAuthenticated = true
            }
        }) {
            TourView().environmentObject(authViewModel)
        }
    }

    private func validateAndSubmit() {
        errorMessage = nil

        guard !fullName.isEmpty, !username.isEmpty, profileImage != nil else {
            errorMessage = "All required fields must be filled out."
            return
        }

        isCreatingAccount = true
        authViewModel.createUserAfterProfileSetup(
            fullName: fullName,
            username: username,
            instagramHandle: instagramHandle,
            profileImage: profileImage,
            password: password
        ) { error in
            if let error = error {
                errorMessage = error
                isCreatingAccount = false
            } else {
                navigateToTour = true
            }
        }
    }

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
}
