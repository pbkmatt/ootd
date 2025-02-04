import SwiftUI

struct SignUpView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var navigateToProfileSetup = false
    @State private var errorMessage: String?

    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 16) {
            Text("Create an Account")
                .font(.custom("BebasNeue-Regular", size: 24))
                .padding(.top, 40)

            // Email
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding(.horizontal)

            // Password
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            // Confirm Password
            SecureField("Confirm Password", text: $confirmPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            // "Next" -> goes to ProfileSetupView if validations pass
            Button("Next") {
                // 1) Confirm both password fields match
                guard password == confirmPassword else {
                    errorMessage = "Passwords do not match."
                    return
                }
                
                // 2) Check if email is valid format
                guard isValidEmail(email) else {
                    errorMessage = "Invalid email format. Please try again."
                    return
                }

                // 3) Check if email is available
                authViewModel.checkEmailAvailability(email: email) { isAvailable, errString in
                    if let err = errString {
                        // e.g., could not query Firestore, etc.
                        errorMessage = err
                    } else if !isAvailable {
                        errorMessage = "Email is already in use."
                    } else {
                        // All good => proceed
                        authViewModel.currentEmail = email
                        authViewModel.currentPassword = password
                        navigateToProfileSetup = true
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.horizontal)

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.custom("OpenSans", size: 14))
                    .padding(.top, 8)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground).ignoresSafeArea())
        // Once validations pass, we move to ProfileSetupView
        .fullScreenCover(isPresented: $navigateToProfileSetup) {
            ProfileSetupView(password: password)
                .environmentObject(authViewModel)
        }
    }
}

// MARK: - Email Format Validation
extension SignUpView {
    private func isValidEmail(_ email: String) -> Bool {
        // A simple, commonly used regex for demonstration.
        // Adjust as needed for more advanced checks.
        let emailRegex = #"^\S+@\S+\.\S+$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }
}
