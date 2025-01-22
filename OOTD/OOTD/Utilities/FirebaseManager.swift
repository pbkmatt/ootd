//
//  FirebaseManager.swift
//  OOTD
//
//  Created by Matt Imhof on 1/19/25.
//


import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class FirebaseManager {
    static let shared = FirebaseManager()
    let auth = Auth.auth()
    let firestore = Firestore.firestore()
    let storage = Storage.storage()

    private init() {}

    func signUp(email: String, password: String, completion: @escaping (Result<AuthDataResult, Error>) -> Void) {
        auth.createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
            } else if let result = result {
                completion(.success(result))
            }
        }
    }

    func logIn(email: String, password: String, completion: @escaping (Result<AuthDataResult, Error>) -> Void) {
        auth.signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
            } else if let result = result {
                completion(.success(result))
            }
        }
    }

    func logOut() throws {
        try auth.signOut()
    }
}
