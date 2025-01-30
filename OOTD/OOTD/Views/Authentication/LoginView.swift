import SwiftUI

struct LoginView: View {
    @State private var emailOrPhone = ""
    @State private var password = ""
    @State private var verificationCode = ""
    @State private var isUsingPhoneAuth = false
    @State private var isVerificationSent = false
    @State private var errorMessage: String?
    
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 16) {
            Text("Log In")
                .font(Font.custom("BebasNeue-Regular", size: 32))
                .padding(.top, 40)

            // Segmented Control for Auth Method
            Picker("Login Method", selection: $isUsingPhoneAuth) {
                Text("Email & Password").tag(false)
                Text("Phone Number").tag(true)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)

            // Email or Phone Input
            TextField(isUsingPhoneAuth ? "Phone Number" : "Email", text: $emailOrPhone)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(isUsingPhoneAuth ? .phonePad : .emailAddress)
                .autocapitalization(.none)
                .padding(.horizontal)

            if isUsingPhoneAuth {
                if isVerificationSent {
                    // OTP Code Entry
                    TextField("Enter Verification Code", text: $verificationCode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .padding(.horizontal)

                    Button("Verify Code") {
                        authViewModel.verifyCode(code: verificationCode) { error in
                            if let error = error {
                                errorMessage = error
                            }
                        }
                    }
                } else {
                    Button("Send Verification Code") {
                        authViewModel.sendVerificationCode(phoneNumber: emailOrPhone) { error in
                            if let error = error {
                                errorMessage = error
                            } else {
                                isVerificationSent = true
                            }
                        }
                    }
                }
            } else {
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                Button("Log In") {
                    authViewModel.logInWithEmail(email: emailOrPhone, password: password) { error in
                        if let error = error {
                            errorMessage = error
                        }
                    }
                }
            }

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
