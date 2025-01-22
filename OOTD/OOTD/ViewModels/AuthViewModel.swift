import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Firebase

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
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
                self.fetchUserDetails(for: user.uid)
                DispatchQueue.main.async {
                    self.isAuthenticated = true
                }
            } else {
                DispatchQueue.main.async {
                    self.isAuthenticated = false
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
            
            // Create user with email and password
            Auth.auth().createUser(withEmail: email, password: password) { result, error in
                if let error = error {
                    completion(error.localizedDescription)
                    return
                }
                
                guard let uid = result?.user.uid else {
                    completion("Failed to retrieve user ID.")
                    return
                }
                
                // Store username and email privately in Firestore
                let userData: [String: Any] = [
                    "username": username.lowercased(),
                    "email": email, // Stored securely and privately
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
                            self.isAuthenticated = true
                        }
                        completion(nil)
                    }
                }
            }
        }
    }

    func logIn(username: String, password: String, completion: @escaping (String?) -> Void) {
        let db = Firestore.firestore()
        
        // Find associated email for the given username
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
            
            // Authenticate user using found email
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

    private func fetchUserDetails(for uid: String) {
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { document, error in
            if let error = error {
                print("Error fetching profile: \(error.localizedDescription)")
            } else if let document = document, document.exists {
                DispatchQueue.main.async {
                    let data = document.data()
                    self.currentUsername = data?["username"] as? String ?? ""
                    self.currentEmail = data?["email"] as? String ?? ""
                    print("✅ User details fetched successfully.")
                }
            } else {
                print("⚠️ No document found for user.")
            }
        }
    }


    func resetPassword(completion: @escaping (String?) -> Void) {
        guard !currentEmail.isEmpty else {
            completion("No email found for password reset.")
            return
        }

        Auth.auth().sendPasswordReset(withEmail: currentEmail) { error in
            if let error = error {
                completion("Failed to send reset email: \(error.localizedDescription)")
            } else {
                completion(nil)
            }
        }
    }
}
