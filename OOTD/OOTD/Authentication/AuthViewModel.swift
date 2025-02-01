import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Firebase

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var needsProfileSetup: Bool = false
    @Published var currentEmail: String = ""
    @Published var currentPhone: String = ""
    @Published var currentPassword: String = ""

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
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.isAuthenticated = true
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

    // MARK: - Create User After Profile Setup
    func createUserAfterProfileSetup(
        fullName: String,
        username: String,
        instagramHandle: String,
        profileImage: UIImage?,
        password: String,
        completion: @escaping (String?) -> Void
    ) {
        Auth.auth().createUser(withEmail: currentEmail, password: password) { result, error in
            if let error = error {
                completion("Error creating user: \(error.localizedDescription)")
                return
            }

            guard let uid = result?.user.uid else {
                completion("Error retrieving user ID.")
                return
            }

            self.uploadProfileImage(profileImage: profileImage, uid: uid) { imageURL in
                let userData: [String: Any] = [
                    "fullName": fullName,
                    "username": username.lowercased(),
                    "instagramHandle": instagramHandle,
                    "profilePictureURL": imageURL ?? "",
                    "email": self.currentEmail,
                    "createdAt": FieldValue.serverTimestamp(),
                    "followersCount": 0,
                    "followingCount": 0,
                    "isPrivateProfile": false
                ]

                self.db.collection("users").document(uid).setData(userData) { error in
                    if let error = error {
                        completion("Error saving user data: \(error.localizedDescription)")
                    } else {
                        DispatchQueue.main.async {
                            self.isAuthenticated = true
                            self.needsProfileSetup = false
                        }
                        completion(nil)
                    }
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
                        self.needsProfileSetup = true
                        self.isAuthenticated = false
                    } else {
                        self.isAuthenticated = true
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

    // MARK: - Upload Profile Picture to Firebase Storage
    private func uploadProfileImage(profileImage: UIImage?, uid: String, completion: @escaping (String?) -> Void) {
        guard let profileImage = profileImage else {
            completion(nil)
            return
        }

        let storageRef = Storage.storage().reference().child("profile_pictures/\(uid).jpg")
        guard let imageData = profileImage.jpegData(compressionQuality: 0.7) else {
            completion(nil)
            return
        }

        storageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                print("Error uploading profile picture: \(error.localizedDescription)")
                completion(nil)
                return
            }

            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Error retrieving image URL: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                completion(url?.absoluteString)
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
                self.currentPassword = ""
                self.verificationID = nil
                self.isVerificationSent = false
                self.authErrorMessage = nil
            }
            print("✅ Successfully signed out.")
        } catch {
            print("❌ Error signing out: \(error.localizedDescription)")
        }
    }

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
    
    // MARK: - Send Phone Number Verification Code
    func sendVerificationCode(phoneNumber: String, completion: @escaping (String?) -> Void) {
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { verificationID, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(error.localizedDescription)
                } else {
                    self.verificationID = verificationID
                    self.isVerificationSent = true
                    completion(nil)
                }
            }
        }
    }

}
