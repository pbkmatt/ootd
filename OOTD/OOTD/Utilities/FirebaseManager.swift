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

    // Email/Password Sign Up
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

    // Phone Authentication: Send Verification Code
    func sendVerificationCode(phoneNumber: String, completion: @escaping (Result<String, Error>) -> Void) {
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { verificationID, error in
            if let error = error {
                completion(.failure(error))
            } else if let verificationID = verificationID {
                completion(.success(verificationID))
            }
        }
    }

    // Verify Code & Sign In
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

    // Create User in Firestore
    private func createUserRecord(uid: String, email: String?, phone: String?) {
        let userData: [String: Any] = [
            "email": email ?? "",
            "phone": phone ?? "",
            "createdAt": FieldValue.serverTimestamp()
        ]
        firestore.collection("users").document(uid).setData(userData)
    }
}
