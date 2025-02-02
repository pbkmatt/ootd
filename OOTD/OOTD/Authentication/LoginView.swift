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
                phoneAuthSection
            } else {
                emailAuthSection
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
        .onAppear {
            errorMessage = nil // Reset errors on view appear
        }
        .fullScreenCover(isPresented: $authViewModel.isAuthenticated) {
            if authViewModel.needsProfileSetup {
                ProfileSetupView(password: password).environmentObject(authViewModel)
            } else {
                LoggedInView().environmentObject(authViewModel)
            }
        }
    }

    // MARK: - Phone Authentication Section
    private var phoneAuthSection: some View {
        VStack {
            if isVerificationSent {
                TextField("Enter Verification Code", text: $verificationCode)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .padding(.horizontal)

                Button("Verify Code") {
                    verifyPhoneCode()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
            } else {
                Button("Send Verification Code") {
                    sendVerificationCode()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Email Authentication Section
    private var emailAuthSection: some View {
        VStack {
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            Button("Log In") {
                loginWithEmail()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.horizontal)
        }
    }

    // MARK: - Authentication Functions
    private func sendVerificationCode() {
        authViewModel.sendVerificationCode(phoneNumber: self.emailOrPhone) { error in
            if let error = error {
                errorMessage = error
            } else {
                isVerificationSent = true
            }
        }
    }

    private func verifyPhoneCode() {
        authViewModel.verifyCode(code: self.verificationCode) { error in
            if let error = error {
                errorMessage = error
            }
        }
    }

    private func loginWithEmail() {
        authViewModel.logInWithEmail(email: emailOrPhone, password: password) { error in
            if let error = error {
                errorMessage = error
            }
        }
    }
}
