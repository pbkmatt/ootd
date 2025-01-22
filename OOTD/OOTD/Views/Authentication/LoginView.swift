import SwiftUI

struct LoginView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isAuthenticated = false
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationView {
            VStack {
                Text("Log In")
                    .font(.largeTitle)
                    .padding()

                TextField("Username", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .padding()

                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button("Log In") {
                    authViewModel.logIn(username: username, password: password) { error in
                        if let error = error {
                            errorMessage = error
                        } else {
                            isAuthenticated = true
                        }
                    }
                }
                .frame(width: 200, height: 50)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding()

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }

                NavigationLink(destination: LoggedInView(), isActive: $isAuthenticated) {
                    EmptyView()
                }
            }
            .padding()
        }
    }
}
