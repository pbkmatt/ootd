import SwiftUI

struct LandingView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Welcome to OOTD")
                    .font(Font.custom("BebasNeue-Regular", size: 32))
                    .padding(.top, 40)

                NavigationLink(destination: SignUpView().environmentObject(authViewModel)) {
                    Text("Sign Up")
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .font(Font.custom("BebasNeue-Regular", size: 18))
                        .cornerRadius(10)
                        .padding(.horizontal, 40)
                }

                NavigationLink(destination: LoginView().environmentObject(authViewModel)) {
                    Text("Log In")
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .font(Font.custom("BebasNeue-Regular", size: 18))
                        .cornerRadius(10)
                        .padding(.horizontal, 40)
                }
            }
            .background(Color(.systemBackground).ignoresSafeArea())
            .fullScreenCover(isPresented: $authViewModel.isAuthenticated) {
                if authViewModel.needsProfileSetup {
                    ProfileSetupView().environmentObject(authViewModel)
                } else {
                    LoggedInView().environmentObject(authViewModel)
                }
            }
        }
    }
}
