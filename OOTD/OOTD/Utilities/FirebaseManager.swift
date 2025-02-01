//  FirebaseManager.swift
//  OOTD

import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class FirebaseManager {
    static let shared = FirebaseManager()
    let auth = Auth.auth()
    let firestore = Firestore.firestore()
    let storage = Storage.storage()

    private init() {}

    // MARK: - Email/Password Sign Up
    func signUpWithEmail(email: String, password: String, completion: @escaping (Result<AuthDataResult, Error>) -> Void) {
        auth.createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
            } else if let result = result {
                self.createUserRecord(uid: result.user.uid, email: email, phone: nil)
                completion(.success(result))
            }
        }
    }

    // MARK: - Phone Authentication
    func sendVerificationCode(phoneNumber: String, completion: @escaping (Result<String, Error>) -> Void) {
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { verificationID, error in
            if let error = error {
                completion(.failure(error))
            } else if let verificationID = verificationID {
                completion(.success(verificationID))
            }
        }
    }

    func verifyCode(verificationID: String, code: String, completion: @escaping (Result<AuthDataResult, Error>) -> Void) {
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: code)
        auth.signIn(with: credential) { result, error in
            if let error = error {
                completion(.failure(error))
            } else if let result = result {
                self.createUserRecord(uid: result.user.uid, email: nil, phone: result.user.phoneNumber)
                completion(.success(result))
            }
        }
    }

    // MARK: - Create User in Firestore
    private func createUserRecord(uid: String, email: String?, phone: String?) {
        let userData: [String: Any] = [
            "email": email ?? "",
            "phone": phone ?? "",
            "createdAt": FieldValue.serverTimestamp()
        ]
        firestore.collection("users").document(uid).setData(userData)
    }

    // MARK: - Fetch Posts (For PostGrid)
    func fetchPosts(filterType: String, lastDocument: DocumentSnapshot?, completion: @escaping ([OOTDPost], DocumentSnapshot?) -> Void) {
        var query: Query = firestore.collection("posts")
            .order(by: "timestamp", descending: true)
            .limit(to: 12) // Fetch 12 posts at a time
        
        // Apply filters based on filterType
        switch filterType {
        case "trending":
            query = firestore.collection("posts").order(by: "likes", descending: true).limit(to: 12)
        case "favorites":
            if let userID = auth.currentUser?.uid {
                query = firestore.collection("posts").whereField("favoritedBy", arrayContains: userID).limit(to: 12)
            }
        case "profilePosts":
            if let userID = auth.currentUser?.uid {
                query = firestore.collection("posts").whereField("userId", isEqualTo: userID).limit(to: 12)
            }
        default:
            break
        }
        
        // Apply pagination if there's a lastDocument
        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }
        
        // Execute query
        query.getDocuments { snapshot, error in
            guard let documents = snapshot?.documents, error == nil else {
                print("Error fetching posts: \(error?.localizedDescription ?? "Unknown error")")
                completion([], nil)
                return
            }
            
            let posts: [OOTDPost] = documents.compactMap { doc in
                try? doc.data(as: OOTDPost.self)
            }
            
            let lastDoc = documents.last // Update last document for pagination
            completion(posts, lastDoc)
        }
    }
}
