import SwiftUI

struct LandingView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Welcome to OOTD")
                    .font(.custom("BebasNeue-Regular", size: 32))
                    .padding(.top, 40)

                // MARK: - Sign Up Navigation
                NavigationLink(destination: SignUpView().environmentObject(authViewModel)) {
                    Text("Sign Up")
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .font(.custom("BebasNeue-Regular", size: 18))
                        .cornerRadius(10)
                        .padding(.horizontal, 40)
                }

                // MARK: - Log In Navigation
                NavigationLink(destination: LoginView().environmentObject(authViewModel)) {
                    Text("Log In")
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .font(.custom("BebasNeue-Regular", size: 18))
                        .cornerRadius(10)
                        .padding(.horizontal, 40)
                }

                Spacer()
            }
            .background(Color(.systemBackground).ignoresSafeArea())
        }
        // MARK: - Single Full Screen Cover to Handle Authentication
        .fullScreenCover(isPresented: $authViewModel.isAuthenticated) {
            if authViewModel.needsProfileSetup {
                ProfileSetupView(password: authViewModel.currentPassword)
                    .environmentObject(authViewModel)
            } else {
                LoggedInView()
                    .environmentObject(authViewModel)
            }
        }
        .onAppear {
            authViewModel.checkAuthState()
        }
    }
}
