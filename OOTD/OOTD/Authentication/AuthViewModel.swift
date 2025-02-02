import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import FirebaseCore

class AuthViewModel: ObservableObject {
    // MARK: - Authentication State
    @Published var isAuthenticated: Bool = false
    @Published var needsProfileSetup: Bool = false
    
    // Store the entire user doc so we can access user.uid, user.username, etc.
    @Published var currentUser: UserModel? = nil

    // MARK: - Temporary Fields for Registration/Phone
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

    // MARK: - Configure Firebase
    private func configureFirebase() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("✅ Firebase configured successfully")
        } else {
            print("⚠️ Firebase already configured.")
        }
        self.checkAuthState()
    }

    // MARK: - Listen for Auth State Changes
    func checkAuthState() {
        Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let user = user {
                    // We have a signed-in user. Let's fetch their doc to populate `currentUser`.
                    self.fetchCurrentUserDoc(uid: user.uid)
                } else {
                    print("❌ No authenticated user. Redirecting to LandingView.")
                    self.isAuthenticated = false
                    self.needsProfileSetup = false
                    self.currentUser = nil
                }
            }
        }
    }

    // MARK: - Fetch Current User Doc
    private func fetchCurrentUserDoc(uid: String) {
        db.collection("users").document(uid).getDocument { document, error in
            if let error = error {
                print("❌ Error fetching user doc: \(error.localizedDescription)")
                self.isAuthenticated = false
                self.needsProfileSetup = false
                self.currentUser = nil
                return
            }
            guard let document = document, document.exists,
                  let userModel = try? document.data(as: UserModel.self) else {
                // doc doesn't exist or can't decode => user needs profile setup
                print("⚠️ No user doc found or failed to decode. Possibly needs profile setup.")
                self.isAuthenticated = false
                self.needsProfileSetup = true
                self.currentUser = nil
                return
            }

            // We have a valid user doc
            // Check if mandatory fields are set
            if userModel.username.isEmpty || userModel.profilePictureURL.isEmpty {
                self.isAuthenticated = false
                self.needsProfileSetup = true
            } else {
                self.isAuthenticated = true
                self.needsProfileSetup = false
            }

            // Store in self.currentUser
            self.currentUser = userModel
            print("✅ Successfully fetched currentUser doc: \(userModel.username)")
        }
    }

    // MARK: - Check Email Availability Before Signup
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
        bio: String,
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

            guard let authResult = result else {
                completion("❌ Auth result is nil.")
                return
            }
            let firebaseUser = authResult.user
            let uid = firebaseUser.uid

            self.uploadProfileImage(profileImage: profileImage, uid: uid) { imageURL in
                let userData: [String: Any] = [
                    "fullName": fullName,
                    "username": username.lowercased(),
                    "bio": bio,
                    "instagramHandle": instagramHandle,
                    "profilePictureURL": imageURL ?? "",
                    "email": self.currentEmail,
                    "createdAt": FieldValue.serverTimestamp(),
                    "followersCount": 0,
                    "followingCount": 0,
                    "isPrivateProfile": false,
                    "uid": uid // ensure we store uid in the doc
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

    // MARK: - Login with Email & Password
    func logInWithEmail(email: String, password: String, completion: @escaping (String?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(error.localizedDescription)
                return
            }
            // If success, we'll get the user in checkAuthState's listener
            // but let's store the email now
            DispatchQueue.main.async {
                self.currentEmail = email
            }
            completion(nil)
        }
    }

    // MARK: - Check User Profile Completion
    // (We replaced this logic with fetchCurrentUserDoc)
    private func checkUserProfileCompletion(for uid: String) {
        // Not used anymore, we do it in fetchCurrentUserDoc
        print("⚠️ checkUserProfileCompletion(for:) is not used. We'll rely on fetchCurrentUserDoc.")
    }

    // MARK: - Phone Verification
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
                    // The auth state listener picks up the new user sign in
                }
                completion(nil)
            }
        }
    }

    func sendVerificationCode(phoneNumber: String, completion: @escaping (String?) -> Void) {
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { verificationID, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error sending verification code: \(error.localizedDescription)")
                    completion(error.localizedDescription)
                } else {
                    self.verificationID = verificationID
                    self.isVerificationSent = true
                    completion(nil)
                }
            }
        }
    }

    // MARK: - Sign Out
    func signOut() {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                print("✅ Successfully signed out. Redirecting to LandingView.")
                self.isAuthenticated = false
                self.needsProfileSetup = false
                self.currentEmail = ""
                self.currentPhone = ""
                self.currentPassword = ""
                self.verificationID = nil
                self.isVerificationSent = false
                self.authErrorMessage = nil
                self.currentUser = nil
            }
        } catch {
            print("❌ Error signing out: \(error.localizedDescription)")
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
}
