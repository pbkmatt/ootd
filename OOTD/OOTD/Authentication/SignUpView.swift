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

            // Confirm
            SecureField("Confirm Password", text: $confirmPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            // "Next" to go to Profile Setup
            Button("Next") {
                guard password == confirmPassword else {
                    errorMessage = "Passwords do not match."
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
            .frame(maxWidth: .infinity)
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
        .fullScreenCover(isPresented: $navigateToProfileSetup) {
            // We present ProfileSetupView to finalize the user doc
            ProfileSetupView(password: password)
                .environmentObject(authViewModel)
        }
    }
}
