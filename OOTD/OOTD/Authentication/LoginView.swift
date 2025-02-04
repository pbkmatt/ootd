import SwiftUI

struct LoginView: View {
    @State private var emailOrPhone = ""
    @State private var password = ""
    @State private var verificationCode = ""
    @State private var isUsingPhoneAuth = false
    @State private var isVerificationSent = false
    @State private var errorMessage: String?

    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss // To pop back to LandingView after login

    var body: some View {
        VStack(spacing: 16) {
            Text("Log In")
                .font(.custom("BebasNeue-Regular", size: 32))
                .padding(.top, 40)

            // Segmented control: Email & Password vs. Phone
            Picker("Login Method", selection: $isUsingPhoneAuth) {
                Text("Email & Password").tag(false)
                Text("Phone Number").tag(true)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)

            // Email/Phone Input
            TextField(isUsingPhoneAuth ? "Phone Number" : "Email", text: $emailOrPhone)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(isUsingPhoneAuth ? .phonePad : .emailAddress)
                .autocapitalization(.none)
                .padding(.horizontal)

            // Show either phone verification or password login
            if isUsingPhoneAuth {
                phoneAuthSection
            } else {
                emailAuthSection
            }

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.custom("OpenSans", size: 14))
                    .padding(.top)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground).ignoresSafeArea())
        .onAppear {
            errorMessage = nil
        }
    }

    // MARK: - Phone Auth Section
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
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
            } else {
                Button("Send Verification Code") {
                    sendVerificationCode()
                }
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Email Auth Section
    private var emailAuthSection: some View {
        VStack {
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            Button("Log In") {
                logInWithEmail()
            }
            .frame(maxWidth: .infinity)
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.horizontal)
        }
    }

    // MARK: - Phone Auth Functions
    private func sendVerificationCode() {
        authViewModel.sendVerificationCode(phoneNumber: emailOrPhone) { error in
            if let error = error {
                errorMessage = error
            } else {
                isVerificationSent = true
            }
        }
    }

    private func verifyPhoneCode() {
        authViewModel.verifyCode(code: verificationCode) { error in
            if let error = error {
                errorMessage = error
            } else {
                handleSuccessfulLogin()
            }
        }
    }

    // MARK: - Email Auth
    private func logInWithEmail() {
        authViewModel.logInWithEmail(email: emailOrPhone, password: password) { error in
            if let error = error {
                self.errorMessage = error
            } else {
                handleSuccessfulLogin()
            }
        }
    }

    // MARK: - Handle Login Success
    private func handleSuccessfulLogin() {
        // Add a short delay to prevent UI clashes before navigating away
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            dismiss()
        }
    }
}
