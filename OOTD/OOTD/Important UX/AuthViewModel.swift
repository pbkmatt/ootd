import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Firebase

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var needsProfileSetup: Bool = false
    @Published var currentEmail: String = ""
    @Published var currentPhone: String = ""

    @Published var verificationID: String? = nil
    @Published var isVerificationSent: Bool = false
    @Published var authErrorMessage: String? = nil

    private let db = Firestore.firestore()

    init() {
        DispatchQueue.main.async {
            self.configureFirebase()
        }
    }

    private func configureFirebase() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("✅ Firebase configured successfully")
        } else {
            print("⚠️ Firebase already configured.")
        }
        self.checkAuthState()
    }

    private func checkAuthState() {
        Auth.auth().addStateDidChangeListener { auth, user in
            if let user = user {
                self.checkUserProfileCompletion(for: user.uid)
            } else {
                DispatchQueue.main.async {
                    self.isAuthenticated = false
                    self.needsProfileSetup = false
                }
            }
        }
    }

    // MARK: - Check Email Uniqueness Before Signup
    func checkEmailAvailability(email: String, completion: @escaping (Bool, String?) -> Void) {
        db.collection("users").whereField("email", isEqualTo: email).getDocuments { snapshot, error in
            if let error = error {
                completion(false, "Error checking email: \(error.localizedDescription)")
                return
            }
            if let snapshot = snapshot, snapshot.documents.isEmpty {
                completion(true, nil) // Email is unique
            } else {
                completion(false, "This email is already in use.")
            }
        }
    }

    // MARK: - Signup with Email (Only After Profile Setup)
    func createUserAfterProfileSetup(password: String, completion: @escaping (String?) -> Void) {
        guard !currentEmail.isEmpty else {
            completion("Email not set during profile setup.")
            return
        }

        Auth.auth().createUser(withEmail: currentEmail, password: password) { result, error in
            if let error = error {
                completion(error.localizedDescription)
                return
            }

            guard let uid = result?.user.uid else {
                completion("Failed to retrieve user ID.")
                return
            }

            // Create user record in Firestore
            let userData: [String: Any] = [
                "email": self.currentEmail,
                "createdAt": FieldValue.serverTimestamp()
            ]

            self.db.collection("users").document(uid).setData(userData) { error in
                if let error = error {
                    completion("Failed to save user data: \(error.localizedDescription)")
                } else {
                    DispatchQueue.main.async {
                        self.needsProfileSetup = true
                    }
                    completion(nil)
                }
            }
        }
    }

    // MARK: - Check User Profile Completion
    private func checkUserProfileCompletion(for uid: String) {
        db.collection("users").document(uid).getDocument { document, error in
            if let error = error {
                print("Error checking profile completion: \(error.localizedDescription)")
                return
            }

            if let document = document, document.exists {
                let data = document.data()
                let fullName = data?["fullName"] as? String ?? ""
                let username = data?["username"] as? String ?? ""
                let profilePictureURL = data?["profilePictureURL"] as? String ?? ""

                DispatchQueue.main.async {
                    if fullName.isEmpty || username.isEmpty || profilePictureURL.isEmpty {
                        self.needsProfileSetup = true  // Send user to Profile Setup
                        self.isAuthenticated = false
                    } else {
                        self.isAuthenticated = true  // Allow login
                        self.needsProfileSetup = false
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.needsProfileSetup = true
                    self.isAuthenticated = false
                }
            }
        }
    }

    // MARK: - Complete Profile Setup
    func completeProfileSetup(fullName: String, username: String, profilePictureURL: String, completion: @escaping (String?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion("User not found.")
            return
        }

        let userRef = db.collection("users").document(uid)
        let updatedData: [String: Any] = [
            "fullName": fullName,
            "username": username.lowercased(),
            "profilePictureURL": profilePictureURL
        ]

        userRef.updateData(updatedData) { error in
            if let error = error {
                completion("Failed to complete profile: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    self.isAuthenticated = true  // Now authenticate the user
                    self.needsProfileSetup = false
                }
                completion(nil)
            }
        }
    }

    // MARK: - Login with Email & Password
    func logInWithEmail(email: String, password: String, completion: @escaping (String?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(error.localizedDescription)
                return
            }

            DispatchQueue.main.async {
                self.isAuthenticated = true
                self.currentEmail = email
            }
            completion(nil)
        }
    }

    // MARK: - Phone Number Signup
    func sendVerificationCode(phoneNumber: String, completion: @escaping (String?) -> Void) {
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { verificationID, error in
            if let error = error {
                completion(error.localizedDescription)
            } else {
                DispatchQueue.main.async {
                    self.verificationID = verificationID
                    self.isVerificationSent = true
                }
                completion(nil)
            }
        }
    }

    // MARK: - Verify Phone Number & Login
    func verifyCode(code: String, completion: @escaping (String?) -> Void) {
        guard let verificationID = self.verificationID else {
            completion("Verification ID is missing. Please request a new code.")
            return
        }

        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: code)
        
        Auth.auth().signIn(with: credential) { result, error in
            if let error = error {
                completion(error.localizedDescription)
                return
            }

            guard let uid = result?.user.uid, let phoneNumber = result?.user.phoneNumber else {
                completion("Failed to retrieve user details.")
                return
            }

            let userRef = self.db.collection("users").document(uid)
            userRef.getDocument { document, error in
                if let error = error {
                    completion("Error checking existing user: \(error.localizedDescription)")
                    return
                }

                if document?.exists == false {
                    let userData: [String: Any] = [
                        "phone": phoneNumber,
                        "createdAt": FieldValue.serverTimestamp()
                    ]
                    userRef.setData(userData)
                }

                DispatchQueue.main.async {
                    self.currentPhone = phoneNumber
                    self.isAuthenticated = true
                }
                completion(nil)
            }
        }
    }

    // MARK: - Sign Out
    func signOut() {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                self.isAuthenticated = false
                self.needsProfileSetup = false
                self.currentEmail = ""
                self.currentPhone = ""
            }
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}
