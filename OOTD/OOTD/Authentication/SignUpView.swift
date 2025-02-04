import SwiftUI

struct SignUpView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var navigateToProfileSetup = false
    @State private var errorMessage: String?

    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 24) {
            Text("Create an Account")
                .font(.custom("BebasNeue-Regular", size: 30))
                .foregroundColor(.primary)
                .padding(.top, 40)

            // MARK: - Email
            TextField("Email", text: $email)
                .font(.custom("OpenSans", size: 16))
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding(.horizontal, 40)

            // MARK: - Password
            SecureField("Password", text: $password)
                .font(.custom("OpenSans", size: 16))
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal, 40)

            // MARK: - Confirm Password
            SecureField("Confirm Password", text: $confirmPassword)
                .font(.custom("OpenSans", size: 16))
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal, 40)

            // MARK: - Next Button
            Button("Next") {
                guard password == confirmPassword else {
                    errorMessage = "Passwords do not match."
                    return
                }
                guard isValidEmail(email) else {
                    errorMessage = "Invalid email format. Please try again."
                    return
                }
                authViewModel.checkEmailAvailability(email: email) { isAvailable, errString in
                    if let err = errString {
                        errorMessage = err
                    } else if !isAvailable {
                        errorMessage = "Email is already in use."
                    } else {
                        authViewModel.currentEmail = email
                        authViewModel.currentPassword = password
                        navigateToProfileSetup = true
                    }
                }
            }
            .font(.custom("BebasNeue-Regular", size: 18))
            .foregroundColor(.white)
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .cornerRadius(12)
            .padding(.horizontal, 40)

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
        .padding(.bottom, 40)
        .background(Color(.systemBackground).ignoresSafeArea())
        .fullScreenCover(isPresented: $navigateToProfileSetup) {
            ProfileSetupView(password: password)
                .environmentObject(authViewModel)
        }
    }
}

// MARK: - Email Format Validation
extension SignUpView {
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^\S+@\S+\.\S+$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }
}
