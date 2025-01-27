import SwiftUI

struct SignUpView: View {
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 16) {
            Text("Create an Account")
                .font(Font.custom("BebasNeue-Regular", size: 24))
                .padding(.top, 40)

            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .padding(.horizontal)

            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.emailAddress)
                .autocorrectionDisabled(true)
                .padding(.horizontal)

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            SecureField("Confirm Password", text: $confirmPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            Button("Sign Up") {
                guard password == confirmPassword else {
                    errorMessage = "Passwords do not match."
                    return
                }

                authViewModel.signUp(username: username, email: email, password: password) { error in
                    if let error = error {
                        errorMessage = error
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.blue)
            .foregroundColor(.white)
            .font(Font.custom("BebasNeue-Regular", size: 18))
            .cornerRadius(10)
            .padding(.horizontal)

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(Font.custom("OpenSans", size: 14))
                    .padding(.top)
            }
        }
        .background(Color(.systemBackground).ignoresSafeArea())
    }
}
