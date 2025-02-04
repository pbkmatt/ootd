import SwiftUI

struct LoginView: View {
    @State private var emailOrPhone = ""
    @State private var password = ""
    @State private var verificationCode = ""
    @State private var isUsingPhoneAuth = false
    @State private var isVerificationSent = false
    @State private var errorMessage: String?

    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Text("Log In")
                .font(.custom("BebasNeue-Regular", size: 32))
                .foregroundColor(.primary)
                .padding(.top, 40)

            // MARK: - Segmented control
            Picker("Login Method", selection: $isUsingPhoneAuth) {
                Text("Email & Password").tag(false)
                Text("Phone Number").tag(true)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 40)

            // MARK: - Email/Phone Input
            TextField(isUsingPhoneAuth ? "Phone Number" : "Email", text: $emailOrPhone)
                .font(.custom("OpenSans", size: 16))
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .keyboardType(isUsingPhoneAuth ? .phonePad : .emailAddress)
                .autocapitalization(.none)
                .padding(.horizontal, 40)

            // MARK: - Phone vs Email Sections - update wknd
            if isUsingPhoneAuth {
                phoneAuthSection
            } else {
                emailAuthSection
            }

            // MARK: - Error Message
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.custom("OpenSans", size: 14))
                    .foregroundColor(.red)
                    .padding(.top, 4)
                    .padding(.horizontal, 40)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .onAppear {
            errorMessage = nil
        }
    }

    // MARK: - Phone Auth Section - rewrite/debug wknd
    private var phoneAuthSection: some View {
        VStack(spacing: 16) {
            if isVerificationSent {
                TextField("Enter Verification Code", text: $verificationCode)
                    .font(.custom("OpenSans", size: 16))
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .keyboardType(.numberPad)
                    .padding(.horizontal, 40)

                Button("Verify Code") {
                    verifyPhoneCode()
                }
                .font(.custom("BebasNeue-Regular", size: 18))
                .foregroundColor(.white)
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .cornerRadius(12)
                .padding(.horizontal, 40)
            } else {
                Button("Send Verification Code") {
                    sendVerificationCode()
                }
                .font(.custom("BebasNeue-Regular", size: 18))
                .foregroundColor(.white)
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .cornerRadius(12)
                .padding(.horizontal, 40)
            }
        }
    }

    // MARK: - Email Auth Section
    private var emailAuthSection: some View {
        VStack(spacing: 16) {
            SecureField("Password", text: $password)
                .font(.custom("OpenSans", size: 16))
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal, 40)

            Button("Log In") {
                logInWithEmail()
            }
            .font(.custom("BebasNeue-Regular", size: 18))
            .foregroundColor(.white)
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .cornerRadius(12)
            .padding(.horizontal, 40)
        }
    }

    // MARK: - Phone Auth Functions - wknd
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            dismiss()
        }
    }
}
