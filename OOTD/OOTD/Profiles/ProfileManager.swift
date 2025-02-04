import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import UIKit
import SwiftUI

class ProfileManager {
    static let shared = ProfileManager()
    private let db = Firestore.firestore()

    // MARK: - Create User Profile
    func createUserProfile(user: UserModel, authViewModel: AuthViewModel, completion: @escaping (Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "User is not authenticated."]))
            return
        }
        
        let userData: [String: Any] = [
            "uid": uid,
            "username": user.username.lowercased(),
            "bio": user.bio,
            "profilePictureURL": user.profilePictureURL,
            "isPrivateProfile": user.isPrivateProfile,
            "createdAt": FieldValue.serverTimestamp(),
            "followersCount": 0,
            "followingCount": 0
        ]
        
        db.collection("users").document(uid).setData(userData) { error in
            if let error = error {
                completion(error)
            } else {
                // Sync AuthViewModel
                DispatchQueue.main.async {
                    authViewModel.currentUser = user
                    authViewModel.isAuthenticated = true
                    authViewModel.needsProfileSetup = false
                }
                completion(nil)
            }
        }
    }

    // MARK: - Fetch User Profile
    func fetchUserProfile(authViewModel: AuthViewModel, completion: @escaping (Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "User is not authenticated."]))
            return
        }
        
        db.collection("users").document(uid).getDocument { document, error in
            if let error = error {
                completion(error)
                return
            }
            
            guard let document = document, document.exists, let data = document.data() else {
                authViewModel.needsProfileSetup = true
                completion(nil)
                return
            }
            
            do {
                let userModel = try document.data(as: UserModel.self)
                DispatchQueue.main.async {
                    authViewModel.currentUser = userModel
                    authViewModel.isAuthenticated = true
                    authViewModel.needsProfileSetup = false
                }
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }

    // MARK: - Update User Profile
    func updateUserProfile(user: UserModel, authViewModel: AuthViewModel, completion: @escaping (Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "User is not authenticated."]))
            return
        }
        
        let userData: [String: Any] = [
            "username": user.username.lowercased(),
            "bio": user.bio,
            "profilePictureURL": user.profilePictureURL,
            "isPrivateProfile": user.isPrivateProfile
        ]
        
        db.collection("users").document(uid).updateData(userData) { error in
            if let error = error {
                completion(error)
            } else {
                DispatchQueue.main.async {
                    authViewModel.currentUser = user
                }
                completion(nil)
            }
        }
    }

    // MARK: - Upload Profile Image
    func uploadProfileImage(image: UIImage?, uid: String, completion: @escaping (String?) -> Void) {
        guard let image = image else {
            completion(nil)
            return
        }
        
        let storageRef = Storage.storage().reference().child("profile_pictures/\(uid).jpg")
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
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
