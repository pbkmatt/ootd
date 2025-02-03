import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import FirebaseCore

class AuthViewModel: ObservableObject {
    // MARK: - Authentication State
    @Published var isAuthenticated: Bool = false
    @Published var needsProfileSetup: Bool = false
    
    // Current user doc
    @Published var currentUser: UserModel? = nil
    
    // MARK: - Temporary Fields
    @Published var currentEmail: String = ""
    @Published var currentPhone: String = ""
    @Published var currentPassword: String = ""

    // For phone auth
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
        checkAuthState()
    }

    // MARK: - Auth State Listener
    func checkAuthState() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let user = user {
                    self.fetchCurrentUserDoc(uid: user.uid)
                } else {
                    print("❌ No authenticated user. Going to LandingView or Login.")
                    self.isAuthenticated = false
                    self.needsProfileSetup = false
                    self.currentUser = nil
                }
            }
        }
    }

    // MARK: - Fetch Current User Doc with Debug
    private func fetchCurrentUserDoc(uid: String) {
        let docRef = db.collection("users").document(uid)
        docRef.getDocument { snapshot, error in
            if let error = error {
                print("❌ Error fetching user doc: \(error.localizedDescription)")
                self.isAuthenticated = false
                self.needsProfileSetup = false
                self.currentUser = nil
                return
            }

            guard let snapshot = snapshot, snapshot.exists else {
                // Doc doesn't exist => possibly a new user
                print("⚠️ No user doc found. Possibly new user => needsProfileSetup.")
                self.isAuthenticated = false
                self.needsProfileSetup = true
                self.currentUser = nil
                return
            }

            // Attempt to decode
            do {
                let userModel = try snapshot.data(as: UserModel.self)
                // If user doc is missing mandatory fields => we might check
                if userModel.username.isEmpty || userModel.profilePictureURL.isEmpty {
                    // incomplete doc
                    self.isAuthenticated = false
                    self.needsProfileSetup = true
                    self.currentUser = userModel
                } else {
                    // doc is good
                    self.isAuthenticated = true
                    self.needsProfileSetup = false
                    self.currentUser = userModel
                }
                print("✅ Fetched and decoded currentUser doc: \(userModel.username)")
                // Debug: Print createdAt if present
                if let createdAtTimestamp = userModel.createdAt {
                    let dateVal = createdAtTimestamp.dateValue()
                    print("🕓 This user was created at: \(dateVal)")
                }
            } catch {
                // If decode fails, we show the reason
                print("❌ Decode error: \(error.localizedDescription)")
                self.isAuthenticated = false
                self.needsProfileSetup = true
                self.currentUser = nil
            }
        }
    }

    // MARK: - Check Email Availability
    func checkEmailAvailability(email: String, completion: @escaping (Bool, String?) -> Void) {
        db.collection("users").whereField("email", isEqualTo: email)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(false, "Error checking email: \(error.localizedDescription)")
                    return
                }
                if let snap = snapshot, snap.documents.isEmpty {
                    completion(true, nil)
                } else {
                    completion(false, "This email is already in use.")
                }
            }
    }

    // MARK: - Create User (with createdAt)
    func createUserAfterProfileSetup(
        fullName: String,
        username: String,
        bio: String,
        instagramHandle: String,
        profileImage: UIImage?,
        password: String,
        completion: @escaping (String?) -> Void
    ) {
        // 1) Create user in Firebase Auth
        Auth.auth().createUser(withEmail: currentEmail, password: password) { result, error in
            if let error = error {
                completion("Error creating user: \(error.localizedDescription)")
                return
            }
            guard let firebaseUser = result?.user else {
                completion("❌ Could not retrieve user from Auth.")
                return
            }
            let uid = firebaseUser.uid

            // 2) Upload profile image if any
            self.uploadProfileImage(profileImage: profileImage, uid: uid) { imageURL in
                // 3) Build user data
                let userData: [String: Any] = [
                    "fullName": fullName,
                    "username": username.lowercased(),
                    "bio": bio,
                    "instagramHandle": instagramHandle,
                    "profilePictureURL": imageURL ?? "",
                    "email": self.currentEmail,
                    "createdAt": FieldValue.serverTimestamp(), // <--- store timestamp
                    "followersCount": 0,
                    "followingCount": 0,
                    "isPrivateProfile": false,
                    "uid": uid
                ]

                // 4) Save doc with the same Auth UID
                self.db.collection("users").document(uid).setData(userData) { err in
                    if let err = err {
                        completion("Error saving user data: \(err.localizedDescription)")
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

    // MARK: - Login With Email
    func logInWithEmail(email: String, password: String, completion: @escaping (String?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { _, error in
            if let error = error {
                completion(error.localizedDescription)
                return
            }
            // If success => Auth state changes => checkAuthState triggers fetch
            DispatchQueue.main.async {
                self.currentEmail = email
            }
            completion(nil)
        }
    }

    // MARK: - Phone Auth
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
            guard let user = result?.user else {
                completion("Failed to retrieve user details.")
                return
            }
            // If no doc => we handle that in fetchCurrentUserDoc
            self.db.collection("users").document(user.uid).getDocument { docSnap, err in
                if let err = err {
                    completion("Error checking existing user: \(err.localizedDescription)")
                    return
                }
                DispatchQueue.main.async {
                    self.currentPhone = user.phoneNumber ?? ""
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
                print("✅ Signed out. Return to LandingView or Login.")
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

    // MARK: - Upload Profile Image
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
                print("Error uploading profile pic: \(error.localizedDescription)")
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
