//
//  ProfileManager.swift
//  OOTD
//
//  Created by Matt Imhof on 1/19/25.
//


import FirebaseFirestore
import FirebaseAuth
import UIKit
import SwiftUI

class ProfileManager {
    static let shared = ProfileManager()
    let db = Firestore.firestore()

    func createUserProfile(user: UserModel, completion: @escaping (Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let userData: [String: Any] = [
            "uid": uid,
            "username": user.username,
            "bio": user.bio,
            "profilePictureURL": user.profilePictureURL,
            "isPrivate": user.isPrivate
        ]
        db.collection("users").document(uid).setData(userData) { error in
            completion(error)
        }
    }

    func fetchUserProfile(completion: @escaping (UserModel?, Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data()
                let user = UserModel(
                    id: data?["uid"] as? String ?? "",
                    username: data?["username"] as? String ?? "",
                    bio: data?["bio"] as? String ?? "",
                    profilePictureURL: data?["profilePictureURL"] as? String ?? "",
                    isPrivate: data?["isPrivate"] as? Bool ?? false
                )
                completion(user, nil)
            } else {
                completion(nil, error)
            }
        }
    }
}
