import SwiftUI

struct LandingView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Text("Welcome to OOTD")
                    .font(.custom("BebasNeue-Regular", size: 36))
                    .foregroundColor(.primary)
                    .padding(.top, 60)

                // MARK: - Sign Up Button
                NavigationLink(destination: SignUpView().environmentObject(authViewModel)) {
                    Text("Sign Up")
                        .font(.custom("BebasNeue-Regular", size: 18))
                        .foregroundColor(.white)
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)

                // MARK: - Log In Button
                NavigationLink(destination: LoginView().environmentObject(authViewModel)) {
                    Text("Log In")
                        .font(.custom("BebasNeue-Regular", size: 18))
                        .foregroundColor(.white)
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.7))
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)

                Spacer()
            }
            .padding(.bottom, 40)
            .background(Color(.systemBackground).ignoresSafeArea())
        }
        // MARK: - using just one single full screen cover
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
