import SwiftUI

struct LoginView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 16) {
            Text("Log In")
                .font(Font.custom("BebasNeue-Regular", size: 32))
                .padding(.top, 40)

            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .padding(.horizontal)

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            Button("Log In") {
                authViewModel.logIn(username: username, password: password) { error in
                    if let error = error {
                        errorMessage = error
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.green)
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
        .padding()
        .background(Color(.systemBackground).ignoresSafeArea())
        .fullScreenCover(isPresented: $authViewModel.isAuthenticated) {
            LoggedInView().environmentObject(authViewModel)
        }
        .fullScreenCover(isPresented: $authViewModel.needsProfileSetup) {
            ProfileSetupView().environmentObject(authViewModel)
        }
    }
}
