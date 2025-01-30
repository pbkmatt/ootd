import SwiftUI

struct SignUpView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var phoneNumber = ""
    @State private var isUsingPhoneAuth = false
    @State private var verificationCode = ""
    @State private var errorMessage: String?
    @State private var isVerificationSent = false
    @State private var emailIsUnique: Bool = false
    @State private var navigateToProfileSetup = false

    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 16) {
            Text("Create an Account")
                .font(Font.custom("BebasNeue-Regular", size: 24))
                .padding(.top, 40)

            Picker("Sign Up Method", selection: $isUsingPhoneAuth) {
                Text("Email & Password").tag(false)
                Text("Phone Number").tag(true)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)

            if isUsingPhoneAuth {
                TextField("Phone Number", text: $phoneNumber)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.phonePad)
                    .padding(.horizontal)

                if isVerificationSent {
                    TextField("Verification Code", text: $verificationCode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .padding(.horizontal)

                    Button(action: {
                        authViewModel.verifyCode(code: verificationCode) { error in
                            if let error = error {
                                errorMessage = error
                            } else {
                                navigateToProfileSetup = true
                            }
                        }
                    }) {
                        Text("Verify Code")
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                } else {
                    Button(action: {
                        authViewModel.sendVerificationCode(phoneNumber: phoneNumber) { error in
                            if let error = error {
                                errorMessage = error
                            } else {
                                isVerificationSent = true
                            }
                        }
                    }) {
                        Text("Send Verification Code")
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            } else {
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding(.horizontal)

                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                SecureField("Confirm Password", text: $confirmPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                Button(action: {
                    guard password == confirmPassword else {
                        errorMessage = "Passwords do not match."
                        return
                    }

                    authViewModel.checkEmailAvailability(email: email) { isAvailable, error in
                        if isAvailable {
                            emailIsUnique = true
                            authViewModel.currentEmail = email
                            navigateToProfileSetup = true
                        } else {
                            errorMessage = error
                        }
                    }
                }) {
                    Text("Next")
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
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
        .fullScreenCover(isPresented: $navigateToProfileSetup) {
            ProfileSetupView().environmentObject(authViewModel)
        }
    }
}
