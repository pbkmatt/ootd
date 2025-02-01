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
                .font(Font.custom("BebasNeue-Regular", size: 24))
                .padding(.top, 40)

            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding(.horizontal)

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            SecureField("Confirm Password", text: $confirmPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            Button("Next") {
                guard password == confirmPassword else {
                    errorMessage = "Passwords do not match."
                    return
                }

                authViewModel.checkEmailAvailability(email: email) { isAvailable, error in
                    if isAvailable {
                        authViewModel.currentEmail = email
                        navigateToProfileSetup = true
                    } else {
                        errorMessage = error
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.horizontal)

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(Font.custom("OpenSans", size: 14))
                    .padding(.top)
            }
        }
        .padding()
        .background(Color(.systemBackground).ignoresSafeArea())
        .fullScreenCover(isPresented: $navigateToProfileSetup) {
            ProfileSetupView(password: password).environmentObject(authViewModel)
        }
    }
}
