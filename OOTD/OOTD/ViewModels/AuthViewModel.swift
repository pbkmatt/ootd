import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Firebase

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var needsProfileSetup: Bool = false // New property
    @Published var currentUsername: String = ""
    @Published var currentEmail: String = ""

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
                self.fetchUserDetails(for: user.uid) { needsSetup in
                    DispatchQueue.main.async {
                        self.isAuthenticated = !needsSetup
                        self.needsProfileSetup = needsSetup
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.isAuthenticated = false
                    self.needsProfileSetup = false
                }
            }
        }
    }

    func signUp(username: String, email: String, password: String, completion: @escaping (String?) -> Void) {
        let db = Firestore.firestore()

        db.collection("users").whereField("username", isEqualTo: username).getDocuments { snapshot, error in
            if let error = error {
                completion("Error checking username: \(error.localizedDescription)")
                return
            }

            if let snapshot = snapshot, !snapshot.isEmpty {
                completion("Username already exists.")
                return
            }

            Auth.auth().createUser(withEmail: email, password: password) { result, error in
                if let error = error {
                    completion(error.localizedDescription)
                    return
                }

                guard let uid = result?.user.uid else {
                    completion("Failed to retrieve user ID.")
                    return
                }

                let userData: [String: Any] = [
                    "username": username.lowercased(),
                    "email": email,
                    "profilePictureURL": "",
                    "bio": "",
                    "fullName": "",
                    "instagramHandle": "",
                    "isPrivateProfile": false,
                    "followersCount": 0,
                    "followingCount": 0,
                    "createdAt": FieldValue.serverTimestamp()
                ]

                db.collection("users").document(uid).setData(userData) { error in
                    if let error = error {
                        completion("Failed to save user data: \(error.localizedDescription)")
                    } else {
                        DispatchQueue.main.async {
                            self.currentUsername = username.lowercased()
                            self.currentEmail = email
                            self.needsProfileSetup = true // Set flag for profile setup
                        }
                        completion(nil)
                    }
                }
            }
        }
    }
    
    func logIn(username: String, password: String, completion: @escaping (String?) -> Void) {
        let db = Firestore.firestore()

        db.collection("users").whereField("username", isEqualTo: username.lowercased()).getDocuments { snapshot, error in
            if let error = error {
                completion("Error finding username: \(error.localizedDescription)")
                return
            }

            guard let document = snapshot?.documents.first,
                  let email = document["email"] as? String else {
                completion("Username not found.")
                return
            }

            Auth.auth().signIn(withEmail: email, password: password) { result, error in
                if let error = error {
                    completion(error.localizedDescription)
                } else {
                    DispatchQueue.main.async {
                        self.currentUsername = username.lowercased()
                        self.currentEmail = email
                        self.isAuthenticated = true
                    }
                    completion(nil)
                }
            }
        }
    }


    func fetchUserDetails(for uid: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { document, error in
            if let error = error {
                print("Error fetching profile: \(error.localizedDescription)")
                completion(false) // Assume no setup needed if there's an error
            } else if let document = document, document.exists {
                DispatchQueue.main.async {
                    let data = document.data()
                    self.currentUsername = data?["username"] as? String ?? ""
                    self.currentEmail = data?["email"] as? String ?? ""

                    // Check if profile setup is incomplete
                    let fullName = data?["fullName"] as? String ?? ""
                    let profilePictureURL = data?["profilePictureURL"] as? String ?? ""
                    completion(fullName.isEmpty || profilePictureURL.isEmpty) // Needs setup if empty
                }
            } else {
                completion(false) // No document, no setup needed
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                self.isAuthenticated = false
                self.currentUsername = ""
                self.currentEmail = ""
            }
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }

}
