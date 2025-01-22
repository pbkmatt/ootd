import SwiftUI
import FirebaseAuth

struct SignUpView: View {
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    @State private var navigateToProfileSetup = false
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        VStack {
            Text("Sign Up")
                .font(.largeTitle)
                .padding()

            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .padding()

            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.emailAddress)
                .autocorrectionDisabled(true)


            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            SecureField("Confirm Password", text: $confirmPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button("Sign Up") {
                guard password == confirmPassword else {
                    errorMessage = "Passwords do not match"
                    return
                }

                authViewModel.signUp(username: username, email: email, password: password) { error in
                    if let error = error {
                        errorMessage = error
                    } else {
                        navigateToProfileSetup = true
                    }
                }
            }
            .frame(width: 200, height: 50)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding()

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .padding()
        .fullScreenCover(isPresented: $navigateToProfileSetup) {
            ProfileSetupView().environmentObject(authViewModel)
        }
    }
}
