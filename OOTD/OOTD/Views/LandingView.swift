import SwiftUI

struct LandingView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationView {
            VStack {
                Text("Welcome to OOTD")
                    .font(.largeTitle)
                    .bold()
                    .padding()

                NavigationLink(destination: SignUpView().environmentObject(authViewModel)) {
                    Text("Sign Up")
                        .frame(width: 200, height: 50)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()

                NavigationLink(destination: LoginView().environmentObject(authViewModel)) {
                    Text("Log In")
                        .frame(width: 200, height: 50)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
            .fullScreenCover(isPresented: $authViewModel.isAuthenticated) {
                LoggedInView().environmentObject(authViewModel)
            }
        }
    }
}
